# Prompt Reescrito — VSCode + Ollama + LLM Local (3 Fases)

> Hardware detectado automaticamente em 2026-08-16 01:23:48 via
> gerar-prompt-ollama.sh (SO identificado: Linux).

Use os 3 prompts abaixo em sequência, na mesma conversa. Deixe o modelo terminar
e valide cada fase antes de mandar a próxima; não é necessário colar a fase
anterior de novo se estiver na mesma conversa.

---

## CONTEXTO E REGRAS GERAIS (repita/anexe em cada fase)

```text
HARDWARE (detectado automaticamente — não substituir por hardware genérico):
```

| Recurso            | Valor                                              |
|---------------------|----------------------------------------------------|
| Sistema operacional | Linux                                        |
| Dispositivo         | Dell Inc. Vostro 5470                                    |
| CPU                 | Intel(R) Core(TM) i7-4510U CPU @ 2.00GHz, x86_64                              |
| Núcleos físicos     | 2 (4 threads lógicas)       |
| RAM                 | 7.7 GiB                                       |
| GPU(s) detectada(s) | Intel Corporation Haswell-ULT Integrated Graphics Controller (rev 0b);NVIDIA Corporation GK208M [GeForce GT 740M] (rev a1)                                        |
| SO / Kernel         | Linux Mint 22 / 6.8.0-136-generic                  |

```text
Avalie explicitamente se a(s) GPU(s) acima (Intel Corporation Haswell-ULT Integrated Graphics Controller (rev 0b);NVIDIA Corporation GK208M [GeForce GT 740M] (rev a1)) são utilizáveis pelo
Ollama hoje (driver, arquitetura, suporte CUDA/ROCm/Metal atual, compatibilidade
com a versão atual do Ollama). Não presuma aceleração útil só por existir uma GPU
dedicada. Se o SO for WSL, avalie também se há suporte a GPU via WSL2
(CUDA on WSL) e as limitações desse cenário.

INFRAESTRUTURA EXISTENTE (preservar, não alterar sem necessidade):

../homelab
├── cli
│   └── comandos
├── docker
│   └── mysqldumps
├── infra
│   ├── automation
│   │   └── n8n
│   │       └── docker-compose.yml
│   ├── databases
│   │   ├── mongodb
│   │   └── mysql
│   │       └── docker-compose.yml
│   ├── dns
│   │   └── pihole
│   │       └── docker-compose.yml
│   ├── ia
│   │   └── ollama
│   │       └── docker-compose.yml
│   ├── management
│   │   └── portainer
│   │       └── docker-compose.yml
│   └── proxy
│       └── nginx
│           ├── docker-compose.yml
│           └── vhosts
│               ├── available
│               └── enabled
│                   ├── financeiro.conf
│                   └── pihole.conf
└── knowledge

Serviços rodando: n8n, MongoDB, MySQL, Pi-hole, Ollama, Portainer, Nginx.

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
```

---

## FASE 1 — Pesquisa e Diagnóstico (sem propor solução ainda)

```text
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
```

```yaml
   services:

  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    init: true

    restart: unless-stopped

    environment:
      OLLAMA_KEEP_ALIVE: 5m
      OLLAMA_MAX_LOADED_MODELS: 1
      OLLAMA_NUM_PARALLEL: 1
      OLLAMA_NUM_THREAD: 6
      OLLAMA_MAX_QUEUE: 2
      OLLAMA_CONTEXT_LENGTH: 512    

    volumes:
      - ./data/ollama:/root/.ollama

    networks:
      - proxy

    cpus: 5
    shm_size: 1g

    healthcheck:
      test: ["CMD", "ollama", "list"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 20s

    logging:
      driver: json-file
      options:
        max-size: "20m"
        max-file: "3"

    security_opt:
      - no-new-privileges:true

  webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui

    restart: unless-stopped

    depends_on:
      ollama:
        condition: service_healthy

    environment:
      OLLAMA_BASE_URL: http://ollama:11434
      WEBUI_URL: http://ollama.web.home

    volumes:
      - ./data/webui:/app/backend/data

    networks:
      - proxy

    mem_limit: 768m
    cpus: 1

    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

    security_opt:
      - no-new-privileges:true

networks:
  proxy:
    external: true
```

```text
   parâmetro por parâmetro: manter / alterar / remover / irrelevante — com justificativa técnica
   ligada a este hardware específico, não "boa prática" genérica.

Não proponha ainda a arquitetura final. Apenas diagnóstico e opções levantadas com
fontes.
```

---

## FASE 2 — Decisão Arquitetural e Configuração Final

```text
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
```

---

## FASE 3 — Automação, Fluxo de Uso e Entrega

```text
Com base nas Fases 1 e 2, usando o CONTEXTO E REGRAS GERAIS, finalize a entrega.

1. Estrutura e função de cada arquivo em `.projeto/specs/` (projeto.md, arquitetura.md,
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
   `.projeto/specs/`, analisar um arquivo, refatorar, corrigir bug, criar função,
   analisar múltiplos arquivos, analisar Git diff, atualizar o `.projeto/specs/`.
5. Limitações explícitas da solução — o que ela NÃO consegue fazer. Não omitir.
6. Resumo final: arquitetura, componentes, modelo principal, decisão sobre
   autocomplete, mecanismo de knowledge, e complexidade (deve ser classificada como
   Baixa).

Entregue o resultado como um documento Markdown organizado (e o script de automação
como arquivo separado), não apenas texto corrido no chat.
```
