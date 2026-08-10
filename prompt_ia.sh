#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Configurações
# ============================================================

DIR=$(pwd)
OUTPUT_FILE="knowledge/contexto_ia.md"

truncate -s 0 $OUTPUT_FILE

# ============================================================
# Funções auxiliares
# ============================================================

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

get_sysctl() {
    local key="$1"

    if value="$(sysctl -n "$key" 2>/dev/null)"; then
        printf '%s' "$value"
    else
        printf '%s' "N/A"
    fi
}

TREE_OUTPUT="$(
   tree \
      -L 6 \
      -I "apps|shared|data|docs|backups|init|scripts" \
      -P "docker-compose.yml|*.conf" \
      --noreport \
      "../$(basename "$DIR")" 2>/dev/null || true
)"

cat >> "$OUTPUT_FILE" <<EOF
# Pesquisa e Projeto — VSCode + Ollama + LLM Local para Desenvolvimento

## 1. PAPEL

Atue como **Arquiteto Sênior de DevOps, Docker, Linux/macOS, Nginx, Ollama, LLMs locais e integração de IA com VSCode**, com experiência prática em ambientes Homelab e desenvolvimento de software.

Seu objetivo é pesquisar, avaliar e projetar a **solução mais simples, rápida, estável e eficiente** para utilizar um LLM local através do Ollama como assistente de programação no VSCode.

Não quero uma arquitetura enterprise.

Quero a **menor arquitetura que resolva corretamente o problema**.

---

# 2. OBJETIVO

Quero chegar ao seguinte fluxo:

\`\`\`text
Desenvolvedor
    ↓
VSCode
    ↓
Chat / Agent / contexto do projeto
    ↓
Ollama
    ↓
LLM local
\`\`\`

O ambiente deve permitir, preferencialmente dentro do VSCode:

* analisar código;
* explicar código;
* corrigir código;
* refatorar código;
* gerar código;
* criar funções;
* identificar bugs;
* analisar erros;
* analisar logs;
* sugerir melhorias;
* analisar arquitetura;
* analisar múltiplos arquivos;
* comparar implementações;
* gerar documentação;
* trabalhar com Git/Git diff;
* utilizar arquivos do workspace como contexto;
* criar ou editar arquivos;
* executar comandos quando a interface/agent permitir;
* manter conversas relacionadas ao projeto.

O objetivo é obter uma experiência de **pair programmer local**.

---

# 3. REQUISITO FUNDAMENTAL

Antes de recomendar qualquer arquitetura, determine:

> Qual é atualmente a forma mais simples e eficiente de integrar o VSCode ao Ollama para desenvolvimento de software, sem utilizar Continue?

Pesquise informações atuais antes de responder.

Não assuma que uma solução continua válida apenas porque era popular anteriormente.

Verifique:

* documentação oficial do VSCode;
* documentação oficial do Ollama;
* documentação oficial das extensões;
* versões atuais;
* suporte atual ao Ollama;
* capacidades atuais de Chat;
* capacidades atuais de Agent;
* suporte a ferramentas;
* suporte a edição de arquivos;
* suporte a workspace;
* suporte a contexto;
* suporte a autocomplete;
* limitações conhecidas.

Sempre que possível, priorize documentação oficial.

---

# 4. HARDWARE REAL

EOF

# ============================================================
# Sistema operacional
# ============================================================

OS="$(uname -s)"
ARCH="$(uname -m)"
HOSTNAME="$(hostname)"

# ============================================================
# Variáveis de Hardware
# ============================================================

OS_FLAVOR="N/A"
MACHINE_MODEL="N/A"
MACHINE_IDENTIFIER="N/A"
CHIP="N/A"
CPU_PLATFORM="N/A"
MEMORY="N/A"

PHYSICAL_CORES="N/A"
PERFORMANCE_CORES="N/A"
EFFICIENCY_CORES="N/A"
LOGICAL_CPUS="N/A"

GPU="N/A"
GPU_TYPE="N/A"

OS_VERSION="N/A"
KERNEL_VERSION="N/A"

print_hardware_table() {

    local col1_width=0
    local col2_width=0

    local rows=(
        "Dispositivo|$MACHINE_MODEL"
        "Modelo|$MACHINE_IDENTIFIER"
        "Chip|$CHIP"
        "Arquitetura|$ARCH"
        "RAM|$MEMORY"
        "Núcleos físicos|$PHYSICAL_CORES"
        "Performance cores|$PERFORMANCE_CORES"
        "Efficiency cores|$EFFICIENCY_CORES"
        "CPUs lógicas|$LOGICAL_CPUS"
        "GPU|$GPU"
        "$OS_FLAVOR|$OS_VERSION"
        "Kernel|$KERNEL_VERSION"
    )

    for row in "${rows[@]}"; do
        IFS='|' read -r col1 col2 <<< "$row"

        (( ${#col1} > col1_width )) && col1_width=${#col1}
        (( ${#col2} > col2_width )) && col2_width=${#col2}
    done

    printf '\n' >> "$OUTPUT_FILE"
    printf 'Considere EXATAMENTE este hardware:\n\n' >> "$OUTPUT_FILE"

    printf '| %-*s | %-*s |\n' \
        "$col1_width" "Recurso" \
        "$col2_width" "Valor" \
        >> "$OUTPUT_FILE"

    printf '|-%-*s-|-%-*s-|\n' \
        "$col1_width" "$(printf '%*s' "$col1_width" '' | tr ' ' '-')" \
        "$col2_width" "$(printf '%*s' "$col2_width" '' | tr ' ' '-')" \
        >> "$OUTPUT_FILE"

    for row in "${rows[@]}"; do
        IFS='|' read -r col1 col2 <<< "$row"

        printf '| %-*s | %-*s |\n' \
            "$col1_width" "$col1" \
            "$col2_width" "$col2" \
            >> "$OUTPUT_FILE"
    done

    printf '\n' >> "$OUTPUT_FILE"
}

# ============================================================
# Identificação do Hardware
# ============================================================

if [[ "$OS" == "Darwin" ]]; then

    OS_FLAVOR="macOS"

    # --------------------------------------------------------
    # Hardware geral
    # --------------------------------------------------------

    HARDWARE_INFO="$(
        system_profiler SPHardwareDataType 2>/dev/null || true
    )"

    # --------------------------------------------------------
    # Modelo
    # --------------------------------------------------------

    MACHINE_MODEL="$(
        printf '%s\n' "$HARDWARE_INFO" |
        awk -F': ' '
            /Model Name/ {
                print $2
                exit
            }
        '
    )"

    # --------------------------------------------------------
    # Identificador
    # --------------------------------------------------------

    MACHINE_IDENTIFIER="$(
        printf '%s\n' "$HARDWARE_INFO" |
        awk -F': ' '
            /Model Identifier/ {
                print $2
                exit
            }
        '
    )"

    # --------------------------------------------------------
    # Chip Apple Silicon
    # --------------------------------------------------------

    CHIP="$(
        printf '%s\n' "$HARDWARE_INFO" |
        awk -F': ' '
            /^ *Chip:/ {
                print $2
                exit
            }
        '
    )"

    # --------------------------------------------------------
    # Processador Intel
    # --------------------------------------------------------

    if [[ -z "$CHIP" ]]; then

        CHIP="$(
            printf '%s\n' "$HARDWARE_INFO" |
            awk -F': ' '
                /^ *Processor Name:/ {
                    print $2
                    exit
                }
            '
        )"

    fi

    if [[ "$ARCH" == "arm64" ]]; then
        CPU_PLATFORM="Apple Silicon"
    elif [[ "$ARCH" == "x86_64" ]]; then
        CPU_PLATFORM="Intel"
    fi    

    # --------------------------------------------------------
    # Memória
    # --------------------------------------------------------

    MEMORY="$(
        printf '%s\n' "$HARDWARE_INFO" |
        awk -F': ' '
            /^ *Memory:/ {
                print $2
                exit
            }
        '
    )"

    # --------------------------------------------------------
    # CPU
    # --------------------------------------------------------

    LOGICAL_CPUS="$(get_sysctl hw.logicalcpu)"
    PHYSICAL_CORES="$(get_sysctl hw.physicalcpu)"

    PERFORMANCE_CORES="$(get_sysctl hw.perflevel0.physicalcpu)"
    EFFICIENCY_CORES="$(get_sysctl hw.perflevel1.physicalcpu)"

    # --------------------------------------------------------
    # GPU
    # --------------------------------------------------------

    GPU="$(
        system_profiler SPDisplaysDataType 2>/dev/null |
        awk -F': ' '
            /Chipset Model:/ {
                print $2
                exit
            }

            /^ *Chip:/ {
                print $2
                exit
            }

            /Graphics:/ {
                print $2
                exit
            }
        '
    )"

    if [[ "$ARCH" == "arm64" ]]; then
        GPU_TYPE="Apple Silicon GPU (integrada ao SoC)"
    elif [[ -n "$GPU" ]]; then
        GPU_TYPE="GPU"
    fi

    # --------------------------------------------------------
    # macOS
    # --------------------------------------------------------

    OS_VERSION="$(
        sw_vers -productVersion 2>/dev/null || true
    )"

    # --------------------------------------------------------
    # Kernel
    # --------------------------------------------------------

    KERNEL_VERSION="$(uname -r)"

elif [[ "$OS" == "Linux" ]]; then

    OS_FLAVOR="Linux"

    # --------------------------------------------------------
    # Arquitetura
    # --------------------------------------------------------

    case "$ARCH" in
        x86_64)
            CPU_PLATFORM="Intel/AMD"
            ;;
        aarch64|arm64)
            CPU_PLATFORM="ARM"
            ;;
    esac

    # --------------------------------------------------------
    # Modelo
    # --------------------------------------------------------

    MACHINE_MODEL="$(
        cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || true
    )

    # --------------------------------------------------------
    # Identificador
    # --------------------------------------------------------

    MACHINE_IDENTIFIER="$(
        cat /sys/devices/virtual/dmi/id/product_version 2>/dev/null || true
    )

    # --------------------------------------------------------
    # CPU
    # --------------------------------------------------------

    CHIP="$(
        lscpu 2>/dev/null |
        awk -F': *' '
            /^Model name:/ {
                print $2
                exit
            }
        '
    )"

    # --------------------------------------------------------
    # Memória
    # --------------------------------------------------------

    MEMORY="$(
        free -h 2>/dev/null |
        awk '
            /^Mem:/ {
                print $2
                exit
            }
        '
    )"

    # --------------------------------------------------------
    # CPU
    # --------------------------------------------------------

    LOGICAL_CPUS="$(
        nproc 2>/dev/null || true
    )"

    PHYSICAL_CORES="$(
        lscpu 2>/dev/null |
        awk -F': *' '
            /^Core\(s\) per socket:/ {
                cores = $2
            }

            /^Socket\(s\):/ {
                sockets = $2
            }

            END {
                if (cores != "" && sockets != "")
                    print cores * sockets
            }
        '
    )"

    # --------------------------------------------------------
    # Performance / Efficiency Cores
    # --------------------------------------------------------
    # Nem todo Linux expõe essa informação.
    # Mantemos vazio quando não estiver disponível.

    PERFORMANCE_CORES=""
    EFFICIENCY_CORES=""

    if [[ -d /sys/devices/system/cpu ]]; then

        PERFORMANCE_CORES="$(
            find /sys/devices/system/cpu \
                -maxdepth 2 \
                -name core_type \
                -type f \
                -exec grep -l '^2$' {} \; 2>/dev/null |
            wc -l |
            awk '{print $1}'
        )"

        EFFICIENCY_CORES="$(
            find /sys/devices/system/cpu \
                -maxdepth 2 \
                -name core_type \
                -type f \
                -exec grep -l '^1$' {} \; 2>/dev/null |
            wc -l |
            awk '{print $1}'
        )"

        [[ "$PERFORMANCE_CORES" == "0" ]] && PERFORMANCE_CORES=""
        [[ "$EFFICIENCY_CORES" == "0" ]] && EFFICIENCY_CORES=""

    fi

    # --------------------------------------------------------
    # GPU
    # --------------------------------------------------------

    GPU="$(
        lspci 2>/dev/null |
        awk -F': ' '
            /VGA compatible controller:/ {
                print $2
                exit
            }

            /3D controller:/ {
                print $2
                exit
            }

            /Display controller:/ {
                print $2
                exit
            }
        '
    )"

    if [[ -n "$GPU" ]]; then
        GPU_TYPE="GPU"
    fi

    # --------------------------------------------------------
    # Linux
    # --------------------------------------------------------

    OS_VERSION="$(
        awk -F= '
            /^PRETTY_NAME=/ {
                gsub(/"/, "", $2)
                print $2
                exit
            }
        ' /etc/os-release 2>/dev/null
    )"

    # --------------------------------------------------------
    # Kernel
    # --------------------------------------------------------

    KERNEL_VERSION="$(uname -r)"

fi

# ============================================================
# Normalização
# ============================================================

[[ -n "$OS_FLAVOR" ]] || OS_FLAVOR="N/A"
[[ -n "$MACHINE_MODEL" ]] || MACHINE_MODEL="N/A"
[[ -n "$MACHINE_IDENTIFIER" ]] || MACHINE_IDENTIFIER="N/A"
[[ -n "$CPU_PLATFORM" ]] || CPU_PLATFORM="N/A"
[[ -n "$CHIP" ]] || CHIP="N/A"
[[ -n "$MEMORY" ]] || MEMORY="N/A"

[[ -n "$PHYSICAL_CORES" ]] || PHYSICAL_CORES="N/A"
[[ -n "$PERFORMANCE_CORES" ]] || PERFORMANCE_CORES="N/A"
[[ -n "$EFFICIENCY_CORES" ]] || EFFICIENCY_CORES="N/A"
[[ -n "$LOGICAL_CPUS" ]] || LOGICAL_CPUS="N/A"

[[ -n "$GPU" ]] || GPU="N/A"
[[ -n "$GPU_TYPE" ]] || GPU_TYPE="N/A"
[[ -n "$OS_VERSION" ]] || OS_VERSION="N/A"
[[ -n "$KERNEL_VERSION" ]] || KERNEL_VERSION="N/A"

print_hardware_table

cat >> "$OUTPUT_FILE" <<EOF
Não substitua essas informações por hardware genérico.

Não utilize Intel, NVIDIA, CUDA ou arquitetura x86 como referência para recomendações de performance.

O ambiente deve ser tratado como:

\`\`\`text
$CPU_PLATFORM
$ARCH
$MEMORY RAM
$PHYSICAL_CORES cores
$GPU_TYPE
Docker
$OS_FLAVOR
\`\`\`

---

# 5. INFRAESTRUTURA EXISTENTE

Estrutura atual:

\`\`\`text
$TREE_OUTPUT
\`\`\`

Os serviços atuais são:

* Nginx;
* Ollama;
* Open WebUI;
* MySQL;
* Pi-hole;
* n8n;
* Portainer.

O objetivo desta pesquisa é **não alterar esses serviços sem necessidade**.

---

# 6. CONFIGURAÇÃO ATUAL DO OLLAMA

Atualmente:

EOF

COMPOSE_FILE_OLLAMA=$(cat "$DIR/infra/ia/ollama/docker-compose.yml")

cat >> "$OUTPUT_FILE" <<EOF
\`\`\`yaml
$COMPOSE_FILE_OLLAMA
\`\`\`
EOF

cat >> "$OUTPUT_FILE" <<EOF
Analise cada parâmetro relacionado ao desempenho do Ollama.

Para cada parâmetro, classifique como:

* **manter**;
* **alterar**;
* **remover**;
* **irrelevante para este cenário**.

Justifique tecnicamente.

Não altere parâmetros apenas por "boa prática".

Qualquer alteração deve ter um benefício esperado para este hardware e objetivo.

---

# 7. NGINX

Atualmente o Ollama está acessível através do Nginx:

\`\`\`text
VSCode
   ↓
Nginx
   ↓
Ollama
\`\`\`

Existe também Open WebUI.

A primeira decisão arquitetural obrigatória é:

> O Nginx é realmente necessário entre o VSCode e o Ollama?

Compare:

\`\`\`text
A)

VSCode
  ↓
Nginx
  ↓
Ollama
\`\`\`

com:

\`\`\`text
B)

VSCode
  ↓
Ollama
\`\`\`

Avalie:

* latência;
* streaming;
* estabilidade;
* timeout;
* configuração;
* segurança;
* manutenção;
* necessidade real;
* impacto no Homelab;
* possibilidade de acesso direto ao Ollama através da rede Docker/host.

Se o Nginx não for necessário para o fluxo VSCode → Ollama, recomende removê-lo **somente desse caminho**, sem alterar outros usos do Nginx.

Não remova o Nginx globalmente se ele continuar sendo necessário para outros serviços.

---

# 8. RESTRIÇÕES

Não utilizar:

* Continue;
* Kubernetes;
* arquitetura distribuída;
* múltiplos servidores de IA;
* múltiplos serviços de IA sem necessidade;
* RAG complexo;
* banco vetorial;
* agentes externos complexos;
* SaaS;
* soluções enterprise;
* indexadores desnecessários;
* infraestrutura adicional apenas para resolver problemas que o VSCode já resolve.

Priorize:

1. simplicidade;
2. baixa latência;
3. estabilidade;
4. qualidade;
5. baixo consumo de RAM/CPU;
6. manutenção;
7. capacidade de compreender contexto.

---

# 9. VSCode — CHAT / AGENT / AUTOCOMPLETE

Analise separadamente:

## 9.1 Chat

Quero saber:

* como conectar o VSCode ao Ollama;
* qual extensão/interface é necessária;
* se existe suporte nativo;
* como selecionar o modelo;
* como fornecer arquivos;
* como utilizar contexto;
* limitações.

## 9.2 Agent

Determine separadamente se a solução permite:

* ler múltiplos arquivos;
* acessar o workspace;
* criar arquivos;
* editar arquivos;
* excluir arquivos;
* executar comandos;
* utilizar ferramentas do VSCode;
* analisar Git;
* analisar Git diff;
* trabalhar iterativamente;
* investigar erros;
* modificar o projeto.

Para cada capacidade, informe **quem fornece a capacidade**:

\`\`\`text
VSCode
Extensão
Ollama
Modelo
\`\`\`

Não atribua ao modelo uma capacidade que na realidade pertence à interface/agent.

## 9.3 Autocomplete

Analise separadamente.

Não assuma que Chat/Agent fornece autocomplete.

Determine:

* se o VSCode possui suporte nativo adequado;
* se Ollama fornece autocomplete diretamente;
* se é necessária uma extensão adicional;
* qual é o custo dessa extensão;
* se o benefício justifica sua inclusão.

Se não houver uma solução simples e satisfatória para autocomplete local com Ollama, diga explicitamente.

Não adicione uma segunda extensão apenas para "completar" a arquitetura.

---

# 10. MODELOS

Pesquise os modelos Ollama atualmente disponíveis e adequados ao hardware informado.

Avalie pelo menos:

* tamanho;
* parâmetros;
* quantização quando relevante;
* RAM necessária;
* contexto;
* velocidade esperada;
* capacidade de programação;
* capacidade de seguir instruções;
* qualidade para refatoração;
* qualidade para análise de código;
* capacidade para contexto maior;
* impacto sobre 8 GB de RAM.

Separe as recomendações em:

### Chat / Agent

Modelo principal recomendado.

### Autocomplete

Somente se fizer sentido.

### Análise de projeto

Modelo recomendado caso seja diferente.

### Documentação

Modelo recomendado caso seja diferente.

Não recomende modelos grandes apenas porque são melhores em benchmarks.

Considere o equilíbrio:

\`\`\`text
qualidade × RAM × latência × contexto
\`\`\`

Se um modelo maior trouxer ganho pequeno e custo elevado neste hardware, prefira o modelo menor.

---

# 11. CONTEXTO DO PROJETO

Quero utilizar arquivos persistentes em:

\`\`\`text
knowledge/
\`\`\`

Estrutura inicial:

\`\`\`text
knowledge/
├── projeto.md
├── arquitetura.md
├── estrutura.md
├── dependencias.md
├── banco.md
├── api.md
└── ajuda_ia.md
\`\`\`

Esses arquivos são:

> **contexto auxiliar persistente**

e NÃO substituem o código-fonte.

Não transforme isso automaticamente em RAG.

Antes de criar qualquer mecanismo de indexação, verifique se o próprio VSCode/interface escolhida já consegue fornecer:

* arquivos do workspace;
* arquivos selecionados;
* contexto da conversa;
* Git diff;
* erros;
* logs;
* ferramentas;
* arquivos Markdown.

A solução deve combinar esses elementos da maneira mais simples possível.

---

# 12. EXCLUSÃO DE CONTEXTO

A solução deve evitar enviar desnecessariamente:

\`\`\`text
.git/
node_modules/
vendor/
.env
.env.*
*.pem
*.key
certificados
dumps grandes
arquivos binários
arquivos temporários
logs gigantes
\`\`\`

Avalie mecanismos como:

\`\`\`text
.gitignore
\`\`\`

e mecanismos próprios da extensão/interface escolhida.

Não invente mecanismos de exclusão que a ferramenta não suporte.

---

# 13. GERAÇÃO DO KNOWLEDGE

Quero um mecanismo simples:

\`\`\`text
Projeto
   ↓
script
   ↓
análise estrutural
   ↓
knowledge/*.md
\`\`\`

O script deve gerar, quando possível:

* estrutura do projeto;
* tecnologias;
* dependências;
* arquivos relevantes;
* pontos de entrada;
* arquitetura;
* banco;
* APIs;
* Docker;
* scripts;
* configurações relevantes;
* contexto para IA.

Compare rapidamente:

* Bash;
* Python;
* VSCode Task;
* CLI.

Escolha apenas uma abordagem principal.

A solução deve ser simples de executar e manter.

---

# 14. IMPORTANTE — LIMITAÇÃO DA GERAÇÃO AUTOMÁTICA

Não assuma que um script Bash/Python consegue compreender semanticamente toda a arquitetura de um projeto.

Separe:

### Informação determinística

Pode ser obtida automaticamente:

* tree;
* nomes de arquivos;
* extensões;
* package.json;
* composer.json;
* requirements.txt;
* Dockerfile;
* docker-compose.yml;
* arquivos de configuração;
* Git;
* scripts.

### Informação semântica

Pode exigir LLM:

* finalidade do projeto;
* arquitetura;
* relacionamentos;
* responsabilidades;
* regras de negócio;
* dependências arquiteturais;
* pontos problemáticos.

Se a geração de determinada informação exigir IA, deixe isso explícito.

Não crie um script artificialmente complexo apenas para evitar o uso do LLM.

---

# 15. SEGURANÇA

Avalie:

* exposição da API do Ollama;
* acesso pela rede Docker;
* acesso pelo host;
* necessidade de autenticação;
* exposição externa;
* riscos de publicar \`11434\`;
* interação com Nginx;
* riscos de agentes executarem comandos;
* exposição de secrets ao modelo.

Não transforme segurança em uma arquitetura excessiva.

Priorize segurança proporcional a um Homelab.

---

# 16. PESQUISA

A pesquisa deve utilizar informações atuais.

Para informações que podem mudar com o tempo, como:

* versões;
* extensões;
* APIs;
* suporte do VSCode;
* suporte ao Ollama;
* modelos;
* parâmetros do Ollama;
* capacidades de Agent;
* autocomplete;

verifique fontes atuais.

Priorize:

1. documentação oficial;
2. GitHub oficial;
3. documentação da extensão;
4. documentação do Ollama;
5. documentação do VSCode;
6. fontes técnicas confiáveis.

Não baseie decisões importantes apenas em posts antigos, blogs ou vídeos.

Para cada informação crítica que mudou recentemente, informe:

\`\`\`text
Fonte:
Data:
Versão:
\`\`\`

Se houver conflito entre fontes, explique o conflito e escolha a informação mais confiável.

Não invente funcionalidades.

Se não conseguir confirmar uma capacidade, escreva:

> "Não confirmado."

---

# 17. METODOLOGIA DA ANÁLISE

Execute a análise nesta ordem:

## Etapa 1 — Diagnóstico

Identifique:

* problemas;
* gargalos;
* configurações desnecessárias;
* inconsistências;
* riscos;
* limitações;
* possíveis fontes de latência.

Não faça alterações ainda.

---

## Etapa 2 — Decisão arquitetural

Determine:

\`\`\`text
VSCode
   ↓
?
   ↓
Ollama
   ↓
Modelo
\`\`\`

Defina o menor número possível de componentes.

Explique por que cada componente existe.

---

## Etapa 3 — VSCode

Determine a solução principal para:

* Chat;
* Agent;
* contexto;
* edição;
* workspace;
* Git.

Depois avalie autocomplete separadamente.

---

## Etapa 4 — Ollama

Avalie:

* imagem;
* arquitetura;
* parâmetros;
* CPU;
* RAM;
* contexto;
* concorrência;
* modelos;
* persistência.

---

## Etapa 5 — Contexto

Defina:

\`\`\`text
knowledge/
\`\`\`

e como ele será utilizado.

---

## Etapa 6 — Automação

Escolha um mecanismo simples para gerar/atualizar o knowledge.

---

## Etapa 7 — Segurança

Avalie apenas os riscos relevantes.

---

## Etapa 8 — Operação

Forneça os comandos necessários para:

\`\`\`text
subir
parar
reiniciar
ver status
ver logs
testar Ollama
testar modelo
testar API
testar Nginx
testar VSCode → Ollama
\`\`\`

---

# 18. CLASSIFICAÇÃO DAS ALTERAÇÕES

Toda alteração proposta deve ser classificada como:

### OBRIGATÓRIO

Sem isso a solução não funciona corretamente.

### RECOMENDADO

Melhora significativamente o resultado.

### OPCIONAL

Pode melhorar algo, mas não é necessário.

Não transforme recomendações opcionais em requisitos.

---

# 19. FORMATO DA RESPOSTA

Estruture a resposta exatamente nesta ordem:

## 1. Resumo executivo

Em poucas linhas:

* qual é a arquitetura recomendada;
* qual interface/integração usar;
* qual modelo principal;
* se Nginx deve permanecer no caminho;
* se autocomplete deve ser utilizado;
* qual mecanismo usar para \`knowledge/\`.

---

## 2. Arquitetura final

Mostrar um diagrama:

\`\`\`text
VSCode
  ↓
Interface/Extensão
  ↓
Ollama
  ↓
LLM
\`\`\`

Inclua somente componentes realmente necessários.

---

## 3. Diagnóstico do ambiente atual

Tabela:

| Item | Situação | Problema | Ação | Prioridade |
| ---- | -------- | -------- | ---- | ---------- |

---

## 4. VSCode

Explique:

* solução escolhida;
* por que foi escolhida;
* Chat;
* Agent;
* contexto;
* workspace;
* Git;
* edição;
* comandos;
* limitações.

---

## 5. Autocomplete

Análise independente.

Se recomendado:

* ferramenta;
* motivo;
* impacto.

Se não recomendado:

> "Não recomendo neste cenário."

Explique por quê.

---

## 6. Ollama

Mostre a configuração final.

Para cada alteração:

\`\`\`text
Arquivo:
Alteração:
Motivo:
Impacto esperado:
\`\`\`

---

## 7. Modelo(s)

Tabela:

| Uso | Modelo | RAM | Contexto | Qualidade | Latência | Recomendação |
| --- | ------ | --: | -------: | --------- | -------- | ------------ |

Escolha **um modelo principal**.

---

## 8. Knowledge

Mostre:

\`\`\`text
knowledge/
├── projeto.md
├── arquitetura.md
├── estrutura.md
├── dependencias.md
├── banco.md
├── api.md
└── ajuda_ia.md
\`\`\`

Explique a função de cada arquivo.

---

## 9. Automação

Escolha uma única solução principal.

Forneça:

\`\`\`text
caminho/do/script
\`\`\`

e o conteúdo completo.

Explique:

* o que ele coleta;
* o que ele não coleta;
* como executar;
* como atualizar.

---

## 10. Segurança

Liste somente os riscos relevantes e as respectivas ações.

---

## 11. Operação

Forneça comandos para:

\`\`\`text
subir
parar
reiniciar
logs
status
teste Ollama
teste modelo
teste API
teste Nginx
teste VSCode
\`\`\`

---

## 12. Fluxo de uso

Demonstre exemplos reais:

\`\`\`text
@chat

Analise este projeto.

Considere:
knowledge/projeto.md
knowledge/arquitetura.md
knowledge/estrutura.md

Identifique os principais problemas arquiteturais.
\`\`\`

Depois exemplos de:

* análise de arquivo;
* refatoração;
* correção de bug;
* criação de função;
* análise de múltiplos arquivos;
* análise de Git diff;
* atualização do \`knowledge/\`.

---

## 13. Limitações

Liste explicitamente o que a solução **não consegue fazer**.

Não esconda limitações.

---

## 14. Resultado final

Finalize com:

### Arquitetura recomendada

\`\`\`text
...
\`\`\`

### Componentes

\`\`\`text
...
\`\`\`

### Modelo principal

\`\`\`text
...
\`\`\`

### Autocomplete

\`\`\`text
...
\`\`\`

### Knowledge

\`\`\`text
...
\`\`\`

### Complexidade

Classifique:

\`\`\`text
Baixa / Média / Alta
\`\`\`

A solução desejada deve ser **Baixa**.

---

# 20. REGRAS ABSOLUTAS

1. Não invente informações.
2. Não invente funcionalidades de VSCode, extensões, Ollama ou modelos.
3. Não invente benchmarks.
4. Não assuma suporte a Agent sem verificar.
5. Não assuma suporte a autocomplete sem verificar.
6. Não assuma que Chat e Agent possuem as mesmas capacidades.
7. Não assuma que o modelo controla o workspace.
8. Não confunda capacidade do modelo com capacidade da interface.
9. Não recomende Continue.
10. Não recomende Kubernetes.
11. Não recomende RAG sem necessidade comprovada.
12. Não recomende banco vetorial sem necessidade comprovada.
13. Não adicione serviços apenas por "boa prática".
14. Não altere componentes existentes sem justificar.
15. Não altere parâmetros do Ollama sem explicar o benefício.
16. Não utilize hardware diferente do informado.
17. Considere sempre 8 GB de RAM.
18. Considere sempre Apple Silicon / arm64.
19. Priorize baixa latência.
20. Priorize simplicidade.
21. Escolha uma solução principal.
22. Não apresente dez alternativas equivalentes.
23. Quando houver alternativas relevantes, compare-as e escolha uma.
24. Diferencie claramente fato, inferência e recomendação.
25. Se uma informação não puder ser confirmada, diga explicitamente.
26. Se faltar informação realmente crítica, pergunte antes de definir a configuração final.
27. Não faça overengineering.
28. Preserve a infraestrutura existente sempre que possível.

---

# 21. DECISÃO FINAL

O objetivo não é construir a solução tecnicamente mais sofisticada.

O objetivo é determinar:

> **Qual é a menor arquitetura capaz de fornecer uma boa experiência de pair programming local no VSCode utilizando Ollama, considerando especificamente um MacBook Neo com Apple A18 Pro e 8 GB de RAM?**

A resposta deve privilegiar:

\`\`\`text
simplicidade
    +
baixa latência
    +
estabilidade
    +
qualidade suficiente
    +
baixo consumo
\`\`\`

e não quantidade de componentes ou funcionalidades.

Não recomende complexidade sem demonstrar claramente qual problema ela resolve.
EOF