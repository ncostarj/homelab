# Pesquisa e Projeto — VSCode + Ollama + LLM Local para Desenvolvimento

## 1. PAPEL

Atue como **Arquiteto Sênior de DevOps, Docker, Linux/macOS, Nginx, Ollama, LLMs locais e integração de IA com VSCode**, com experiência prática em ambientes Homelab e desenvolvimento de software.

Seu objetivo é pesquisar, avaliar e projetar a **solução mais simples, rápida, estável e eficiente** para utilizar um LLM local através do Ollama como assistente de programação no VSCode.

Não quero uma arquitetura enterprise.

Quero a **menor arquitetura que resolva corretamente o problema**.

---

# 2. OBJETIVO

Quero chegar ao seguinte fluxo:

```text
Desenvolvedor
    ↓
VSCode
    ↓
Chat / Agent / contexto do projeto
    ↓
Ollama
    ↓
LLM local
```

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

Considere EXATAMENTE este hardware:

| Recurso           | Valor                                                                 |
|-------------------|-----------------------------------------------------------------------|
| Dispositivo       | Vostro 5470                                                           |
| Modelo            | 0F7NWH                                                                |
| Chip              | Intel(R) Core(TM) i7-4510U CPU @ 2.00GHz                              |
| Arquitetura       | x86_64                                                                |
| RAM               | 7.7 GiB                                                               |
| Núcleos físicos   | 2                                                                     |
| Performance cores | N/A                                                                   |
| Efficiency cores  | N/A                                                                   |
| CPUs lógicas      | 4                                                                     |
| GPU               | Intel Corporation Haswell-ULT Integrated Graphics Controller (rev 0b) |
| Linux             | Linux Mint 22                                                         |
| Kernel            | 6.8.0-136-generic                                                     |

Não substitua essas informações por hardware genérico.

Não utilize Intel, NVIDIA, CUDA ou arquitetura x86 como referência para recomendações de performance.

O ambiente deve ser tratado como:

```text
Intel/AMD
x86_64
7.7 GiB RAM
2 cores
N/A
Docker
Linux
```

---

# 5. INFRAESTRUTURA EXISTENTE

Estrutura atual:

```text
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
```

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

```yaml
services:

  ollama:
    image: ollama/ollama:latest
    platform: linux/arm64
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
    platform: linux/arm64
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

```text
VSCode
   ↓
Nginx
   ↓
Ollama
```

Existe também Open WebUI.

A primeira decisão arquitetural obrigatória é:

> O Nginx é realmente necessário entre o VSCode e o Ollama?

Compare:

```text
A)

VSCode
  ↓
Nginx
  ↓
Ollama
```

com:

```text
B)

VSCode
  ↓
Ollama
```

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

```text
VSCode
Extensão
Ollama
Modelo
```

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

```text
qualidade × RAM × latência × contexto
```

Se um modelo maior trouxer ganho pequeno e custo elevado neste hardware, prefira o modelo menor.

---

# 11. CONTEXTO DO PROJETO

Quero utilizar arquivos persistentes em:

```text
.projeto/specs/
```

Estrutura inicial:

```text
.projeto/specs/
├── projeto.md
├── arquitetura.md
├── estrutura.md
├── dependencias.md
├── banco.md
├── api.md
└── ajuda_ia.md
```

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

```text
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
```

Avalie mecanismos como:

```text
.gitignore
```

e mecanismos próprios da extensão/interface escolhida.

Não invente mecanismos de exclusão que a ferramenta não suporte.

---

# 13. GERAÇÃO DO KNOWLEDGE

Quero um mecanismo simples:

```text
Projeto
   ↓
script
   ↓
análise estrutural
   ↓
.projeto/specs/*.md
```

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
* riscos de publicar `11434`;
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

```text
Fonte:
Data:
Versão:
```

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

```text
VSCode
   ↓
?
   ↓
Ollama
   ↓
Modelo
```

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

```text
.projeto/specs/
```

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

```text
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
```

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
* qual mecanismo usar para `.projeto/specs/`.

---

## 2. Arquitetura final

Mostrar um diagrama:

```text
VSCode
  ↓
Interface/Extensão
  ↓
Ollama
  ↓
LLM
```

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

```text
Arquivo:
Alteração:
Motivo:
Impacto esperado:
```

---

## 7. Modelo(s)

Tabela:

| Uso | Modelo | RAM | Contexto | Qualidade | Latência | Recomendação |
| --- | ------ | --: | -------: | --------- | -------- | ------------ |

Escolha **um modelo principal**.

---

## 8. Knowledge

Mostre:

```text
.projeto/specs/
├── projeto.md
├── arquitetura.md
├── estrutura.md
├── dependencias.md
├── banco.md
├── api.md
└── ajuda_ia.md
```

Explique a função de cada arquivo.

---

## 9. Automação

Escolha uma única solução principal.

Forneça:

```text
caminho/do/script
```

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

```text
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
```

---

## 12. Fluxo de uso

Demonstre exemplos reais:

```text
@chat

Analise este projeto.

Considere:
.projeto/specs/projeto.md
.projeto/specs/arquitetura.md
.projeto/specs/estrutura.md

Identifique os principais problemas arquiteturais.
```

Depois exemplos de:

* análise de arquivo;
* refatoração;
* correção de bug;
* criação de função;
* análise de múltiplos arquivos;
* análise de Git diff;
* atualização do `.projeto/specs/`.

---

## 13. Limitações

Liste explicitamente o que a solução **não consegue fazer**.

Não esconda limitações.

---

## 14. Resultado final

Finalize com:

### Arquitetura recomendada

```text
...
```

### Componentes

```text
...
```

### Modelo principal

```text
...
```

### Autocomplete

```text
...
```

### Knowledge

```text
...
```

### Complexidade

Classifique:

```text
Baixa / Média / Alta
```

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

```text
simplicidade
    +
baixa latência
    +
estabilidade
    +
qualidade suficiente
    +
baixo consumo
```

e não quantidade de componentes ou funcionalidades.

Não recomende complexidade sem demonstrar claramente qual problema ela resolve.
