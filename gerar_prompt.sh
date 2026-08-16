#!/usr/bin/env bash
#
# gerar-prompt-ollama.sh
#
# Detecta o hardware atual (macOS, Linux ou WSL) e gera o documento
# "prompt-vscode-ollama-reescrito.md" com as 3 fases (pesquisa/diagnóstico,
# decisão arquitetural, automação/entrega), preenchendo a tabela de hardware
# dinamicamente em vez de valores fixos de uma máquina específica.
#
# Uso:
#   ./gerar-prompt-ollama.sh [arquivo_de_saida.md]
#
# Padrão de saída: ./prompt-vscode-ollama-reescrito.md

set -euo pipefail

OUTFILE="${1:-prompt-vscode-ollama-reescrito.md}"

# ---------------------------------------------------------------------------
# 1. Detecção de sistema operacional
# ---------------------------------------------------------------------------

detect_os() {
    local kernel
    kernel="$(uname -s)"

    if [[ "$kernel" == "Darwin" ]]; then
        echo "macos"
        return
    fi

    if [[ "$kernel" == "Linux" ]]; then
        if grep -qiE "microsoft|wsl" /proc/version 2>/dev/null; then
            echo "wsl"
        else
            echo "linux"
        fi
        return
    fi

    echo "desconhecido"
}

OS_TYPE="$(detect_os)"

# ---------------------------------------------------------------------------
# 2. Coleta de hardware por SO
# ---------------------------------------------------------------------------

get_device_model() {
    case "$OS_TYPE" in
        macos)
            sysctl -n hw.model 2>/dev/null || echo "não identificado"
            ;;
        linux)
            if [[ -r /sys/class/dmi/id/product_name ]]; then
                local vendor product
                vendor="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
                product="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
                echo "${vendor:-} ${product:-}" | sed 's/^ *//;s/ *$//'
            else
                echo "não identificado (sem acesso a /sys/class/dmi)"
            fi
            ;;
        wsl)
            if command -v powershell.exe &>/dev/null; then
                powershell.exe -NoProfile -Command \
                    "(Get-CimInstance Win32_ComputerSystem).Manufacturer + ' ' + (Get-CimInstance Win32_ComputerSystem).Model" \
                    2>/dev/null | tr -d '\r' | sed '/^\s*$/d' || echo "não identificado (host Windows)"
            else
                echo "não identificado (powershell.exe indisponível no WSL)"
            fi
            ;;
        *)
            echo "não identificado"
            ;;
    esac
}

get_cpu_model() {
    case "$OS_TYPE" in
        macos)
            sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "não identificado"
            ;;
        linux|wsl)
            if command -v lscpu &>/dev/null; then
                lscpu | awk -F': +' '/^Nome do modelo/ {print $2; exit}'
            elif [[ -r /proc/cpuinfo ]]; then
                awk -F': ' '/Nome do modelo/ {print $2; exit}' /proc/cpuinfo
            else
                echo "não identificado"
            fi
            ;;
        *)
            echo "não identificado"
            ;;
    esac
}

get_arch() {
    uname -m
}

get_physical_cores() {
    case "$OS_TYPE" in
        macos)
            sysctl -n hw.physicalcpu 2>/dev/null || echo "N/A"
            ;;
        linux|wsl)
            if command -v lscpu &>/dev/null; then
                lscpu | awk -F': +' '
                    /^Núcleo\(s\) por soquete/ {cores=$2}
                    /^Soquete\(s\)/ {sockets=$2}
                    END {
                        if (cores != "" && sockets != "") print cores * sockets
                        else print "N/A"
                    }'
            else
                echo "N/A"
            fi
            ;;
        *)
            echo "N/A"
            ;;
    esac
}

get_logical_cores() {
    case "$OS_TYPE" in
        macos)
            sysctl -n hw.logicalcpu 2>/dev/null || echo "N/A"
            ;;
        linux|wsl)
            nproc 2>/dev/null || echo "N/A"
            ;;
        *)
            echo "N/A"
            ;;
    esac
}

get_ram() {
    case "$OS_TYPE" in
        macos)
            local bytes
            bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
            awk -v b="$bytes" 'BEGIN{printf "%.1f GiB", b/1024/1024/1024}'
            ;;
        linux|wsl)
            if [[ -r /proc/meminfo ]]; then
                awk '/MemTotal/ {printf "%.1f GiB", $2/1024/1024}' /proc/meminfo
            else
                echo "N/A"
            fi
            ;;
        *)
            echo "N/A"
            ;;
    esac
}

get_gpu() {
    case "$OS_TYPE" in
        macos)
            if command -v system_profiler &>/dev/null; then
                system_profiler SPDisplaysDataType 2>/dev/null \
                    | awk -F': ' '/Chipset Model/ {print $2}' \
                    | paste -sd '; ' -
            else
                echo "não identificado"
            fi
            ;;
        linux)
            if command -v lspci &>/dev/null; then
                lspci | grep -Ei 'vga|3d controller|display controller' \
                    | sed -E 's/^[0-9a-f:.]+ [A-Za-z0-9 ]+: //' \
                    | paste -sd '; ' -
            else
                echo "lspci indisponível — não foi possível detectar GPU"
            fi
            ;;
        wsl)
            # WSL normalmente não expõe GPU via lspci (sem passthrough de PCI).
            # Tenta consultar o host Windows via powershell.exe, se disponível.
            if command -v powershell.exe &>/dev/null; then
                powershell.exe -NoProfile -Command \
                    "(Get-CimInstance Win32_VideoController).Name" \
                    2>/dev/null | tr -d '\r' | sed '/^\s*$/d' | paste -sd '; ' -
            else
                echo "Não confirmado — WSL não expõe GPU diretamente sem powershell.exe"
            fi
            ;;
        *)
            echo "não identificado"
            ;;
    esac
}

get_os_version() {
    case "$OS_TYPE" in
        macos)
            local name ver
            name="$(sw_vers -productName 2>/dev/null || echo macOS)"
            ver="$(sw_vers -productVersion 2>/dev/null || echo "?")"
            echo "$name $ver"
            ;;
        linux|wsl)
            if [[ -r /etc/os-release ]]; then
                # shellcheck disable=SC1091
                . /etc/os-release
                echo "${PRETTY_NAME:-Linux}"
            else
                uname -a
            fi
            ;;
        *)
            echo "desconhecido"
            ;;
    esac
}

get_kernel() {
    uname -r
}

get_tree() {
   TREE_OUTPUT="$(
   tree \
      -L 6 \
      -I "apps|shared|data|docs|backups|init|scripts" \
      -P "docker-compose.yml|*.conf" \
      --noreport \
      "../$(basename "$PWD")" 2>/dev/null || true
   )"
   echo "$TREE_OUTPUT"
}

get_services() {
    services=""

    for category in "$PWD/infra"/*/; do
        [ -d "$category" ] || continue

        for service in "$category"/*; do
            [ -d "$service" ] || continue

            service_name=$(basename "$service")

            case "$service_name" in
                n8n)
                    name="n8n"
                    ;;
                mongodb)
                    name="MongoDB"
                    ;;
                mysql)
                    name="MySQL"
                    ;;
                pihole)
                    name="Pi-hole"
                    ;;
                ollama)
                    name="Ollama"
                    ;;
                portainer)
                    name="Portainer"
                    ;;
                nginx)
                    name="Nginx"
                    ;;
            esac            

            if [ -n "$services" ]; then
                services="$services, $name"
            else
                services="$service_name"
            fi
        done
    done

    echo "$services"   
}

get_ollama_compose() {
    OLLAMA_COMPOSE_FILE=$(cat ./infra/ia/ollama/docker-compose.yml)
    echo "$OLLAMA_COMPOSE_FILE"
}

# ---------------------------------------------------------------------------
# 3. Monta os valores coletados
# ---------------------------------------------------------------------------

DEVICE_MODEL="$(get_device_model)"
CPU_MODEL="$(get_cpu_model)"
ARCH="$(get_arch)"
PHYS_CORES="$(get_physical_cores)"
LOG_CORES="$(get_logical_cores)"
RAM_TOTAL="$(get_ram)"
GPU_INFO="$(get_gpu)"
OS_VERSION="$(get_os_version)"
KERNEL_VERSION="$(get_kernel)"
TREE="$(get_tree)"
SERVICES="$(get_services)"
OLLAMA_COMPOSE="$(get_ollama_compose)"

[[ -z "$DEVICE_MODEL" ]] && DEVICE_MODEL="não identificado"
[[ -z "$CPU_MODEL" ]] && CPU_MODEL="não identificado"
[[ -z "$GPU_INFO" ]] && GPU_INFO="não identificado"

OS_LABEL="Linux"
[[ "$OS_TYPE" == "macos" ]] && OS_LABEL="macOS"
[[ "$OS_TYPE" == "wsl" ]] && OS_LABEL="WSL (Windows Subsystem for Linux)"

# ---------------------------------------------------------------------------
# 4. Gera o documento final (idêntico em estrutura ao prompt em 3 fases,
#    com a tabela/bloco de hardware preenchido dinamicamente)
# ---------------------------------------------------------------------------

cat > "$OUTFILE" <<EOF
# Prompt Reescrito — VSCode + Ollama + LLM Local (3 Fases)

> Hardware detectado automaticamente em $(date '+%Y-%m-%d %H:%M:%S') via
> gerar-prompt-ollama.sh (SO identificado: ${OS_LABEL}).

Use os 3 prompts abaixo em sequência, na mesma conversa. Deixe o modelo terminar
e valide cada fase antes de mandar a próxima; não é necessário colar a fase
anterior de novo se estiver na mesma conversa.

---

## CONTEXTO E REGRAS GERAIS (repita/anexe em cada fase)

\`\`\`text
HARDWARE (detectado automaticamente — não substituir por hardware genérico):
\`\`\`

| Recurso            | Valor                                              |
|---------------------|----------------------------------------------------|
| Sistema operacional | ${OS_LABEL}                                        |
| Dispositivo         | ${DEVICE_MODEL}                                    |
| CPU                 | ${CPU_MODEL}, ${ARCH}                              |
| Núcleos físicos     | ${PHYS_CORES} (${LOG_CORES} threads lógicas)       |
| RAM                 | ${RAM_TOTAL}                                       |
| GPU(s) detectada(s) | ${GPU_INFO}                                        |
| SO / Kernel         | ${OS_VERSION} / ${KERNEL_VERSION}                  |

\`\`\`text
Avalie explicitamente se a(s) GPU(s) acima (${GPU_INFO}) são utilizáveis pelo
Ollama hoje (driver, arquitetura, suporte CUDA/ROCm/Metal atual, compatibilidade
com a versão atual do Ollama). Não presuma aceleração útil só por existir uma GPU
dedicada. Se o SO for WSL, avalie também se há suporte a GPU via WSL2
(CUDA on WSL) e as limitações desse cenário.

INFRAESTRUTURA EXISTENTE (preservar, não alterar sem necessidade):

$TREE

Serviços rodando: $SERVICES.

RESTRIÇÕES: não recomendar Continue, Kubernetes, arquitetura distribuída, múltiplos
serviços de IA, RAG complexo, banco vetorial, agentes externos complexos, SaaS,
soluções enterprise, ou qualquer componente adicional sem necessidade comprovada
para este cenário específico.

PRIORIDADE: simplicidade > baixa latência > estabilidade > qualidade suficiente >
baixo consumo de RAM/CPU. Prefira sempre o menor número de componentes que resolve
o problema corretamente — não a solução mais sofisticada.

PADRÃO DE EVIDÊNCIA: toda afirmação sobre versões, extensões, capacidades de
Chat/Agent/Autocomplete, ou modelos deve vir com fonte e data. Se não for
confirmável, escreva "Não confirmado" — não infira. Separe sempre: Fato /
Inferência / Recomendação. Em caso de conflito entre fontes, priorize nesta ordem:
documentação oficial > release notes/changelog oficial > repositório oficial no
GitHub > outras fontes técnicas — e explique o conflito encontrado.

Não atribua a um modelo (LLM) uma capacidade que na verdade pertence à interface/
extensão/agent. Para cada capacidade de Agent, diga explicitamente quem a fornece:
VSCode nativo / Extensão / Ollama / Modelo.
\`\`\`

---

## FASE 1 — Pesquisa e Diagnóstico (sem propor solução ainda)

\`\`\`text
Atue como Arquiteto Sênior de DevOps/Linux/Ollama/integração de IA com VSCode.

Usando o CONTEXTO E REGRAS GERAIS acima, pesquise informações ATUAIS (não assuma que
algo popular no passado continua válido) e responda apenas com um DIAGNÓSTICO — ainda
sem recomendar a arquitetura final.

Pesquise e reporte, com fonte e data para cada item:

1. Qual é hoje a forma mais simples de integrar VSCode ao Ollama para desenvolvimento,
   sem usar a extensão Continue — suporte nativo do VSCode, extensões alternativas,
   Ollama diretamente.
2. Separe e avalie: Chat, Agent, Autocomplete — tratando cada um como capacidades
   independentes (uma solução pode ter uma sem ter as outras). Para cada capacidade
   listada (ler múltiplos arquivos, editar, executar comandos, Git diff, etc.), diga
   quem fornece: VSCode / Extensão / Ollama / Modelo.
3. Se o Nginx é necessário no caminho VSCode → Ollama, ou se acesso direto (rede
   Docker/host) é preferível — avalie latência, streaming, timeout, segurança,
   manutenção.
4. Modelos Ollama atualmente adequados a este hardware, avaliando RAM necessária,
   contexto, velocidade esperada, qualidade para código — para 3 usos possíveis:
   chat/agent principal, autocomplete (se fizer sentido), e análise/documentação
   (se precisar de modelo diferente).
5. Analise minha configuração atual do docker-compose do Ollama 
\`\`\`

\`\`\`yaml
   $OLLAMA_COMPOSE
\`\`\`

\`\`\`text
   parâmetro por parâmetro: manter / alterar / remover / irrelevante — com justificativa técnica
   ligada a este hardware específico, não "boa prática" genérica.

Não proponha ainda a arquitetura final. Apenas diagnóstico e opções levantadas com
fontes.
\`\`\`

---

## FASE 2 — Decisão Arquitetural e Configuração Final

\`\`\`text
Com base no diagnóstico da Fase 1, usando o CONTEXTO E REGRAS GERAIS, decida agora a
arquitetura final.

Entregue:

1. Diagrama final (VSCode → [componente(s) necessários] → Ollama → Modelo), incluindo
   apenas o que é realmente necessário — justifique a existência de cada componente.
2. Decisão sobre Nginx no caminho VSCode↔Ollama (manter fora ou dentro) — uma decisão,
   não alternativas em aberto.
3. Solução escolhida para Chat, para Agent, e para Autocomplete — uma escolha principal
   cada, não uma lista de opções equivalentes. Se não houver solução simples e boa
   para autocomplete local neste cenário, diga isso explicitamente em vez de forçar
   uma extensão extra.
4. Configuração final do docker-compose do Ollama, com cada alteração classificada
   como Arquivo / Alteração / Motivo / Impacto esperado.
5. Um modelo principal recomendado (não uma lista) para chat/agent, com tabela
   Uso | Modelo | RAM | Contexto | Qualidade | Latência | Recomendação.
6. Classifique cada mudança proposta como OBRIGATÓRIO / RECOMENDADO / OPCIONAL.
7. Riscos de segurança relevantes neste Homelab (exposição da API, rede Docker,
   comandos executados por agent) e ação proporcional para cada um — sem propor
   arquitetura de segurança excessiva.

Se faltar alguma informação crítica para fechar a decisão, pergunte antes de definir
a configuração final, em vez de assumir.
\`\`\`

---

## FASE 3 — Automação, Fluxo de Uso e Entrega

\`\`\`text
Com base nas Fases 1 e 2, usando o CONTEXTO E REGRAS GERAIS, finalize a entrega.

1. Estrutura e função de cada arquivo em \`.projeto/specs/\` (projeto.md, arquitetura.md,
   estrutura.md, dependencias.md, banco.md, api.md, ajuda_ia.md).
2. Escolha UMA abordagem de automação (Bash, Python, VSCode Task ou CLI) para gerar/
   atualizar esses arquivos. Separe explicitamente o que é determinístico (tree,
   package.json, Dockerfile, etc. — o script resolve) do que é semântico (arquitetura,
   regras de negócio — exige LLM, não finja que um script resolve isso sozinho).
   Inclua o script completo, mecanismo de exclusão (.gitignore + próprio da
   ferramenta, sem inventar suporte que não existe), como executar e como atualizar.
3. Comandos de operação: subir, parar, reiniciar, status, logs, testar Ollama, testar
   modelo, testar API, testar Nginx (se aplicável), testar VSCode → Ollama.
4. Exemplos reais de uso no VSCode: analisar projeto usando os arquivos de
   \`.projeto/specs/\`, analisar um arquivo, refatorar, corrigir bug, criar função,
   analisar múltiplos arquivos, analisar Git diff, atualizar o \`.projeto/specs/\`.
5. Limitações explícitas da solução — o que ela NÃO consegue fazer. Não omitir.
6. Resumo final: arquitetura, componentes, modelo principal, decisão sobre
   autocomplete, mecanismo de knowledge, e complexidade (deve ser classificada como
   Baixa).

Entregue o resultado como um documento Markdown organizado (e o script de automação
como arquivo separado), não apenas texto corrido no chat.
\`\`\`
EOF

echo "Documento gerado em: $OUTFILE"
echo "SO detectado: $OS_LABEL"
echo "CPU: $CPU_MODEL ($ARCH, ${PHYS_CORES} núcleos físicos / ${LOG_CORES} lógicos)"
echo "RAM: $RAM_TOTAL"
echo "GPU: $GPU_INFO"