# Prompt Reescrito — VSCode + Ollama + LLM Local (3 Fases)

Use os 3 prompts abaixo em sequência, em conversas/turnos separados. Cole a resposta da Fase 1 como contexto (ou referencie-a) ao abrir a Fase 2, e assim por diante.

---

## CONTEXTO E REGRAS GERAIS (repita/anexe em cada fase)

```text
HARDWARE (não substituir por hardware genérico):

| Recurso            | Valor                                              |
|---------------------|----------------------------------------------------|
| Dispositivo         | Vostro 5470 (0F7NWH)                                |
| CPU                 | Intel(R) Core(TM) i7-4510U @ 2.00GHz, x86_64        |
| Núcleos físicos     | 2 (4 threads lógicas)                               |
| RAM                 | 7.7 GiB                                             |
| GPU integrada       | Intel Haswell-ULT Integrated Graphics (rev 0b)      |
| GPU dedicada        | NVIDIA GK208M [GeForce GT 740M] (rev a1)            |
| SO                  | Linux Mint 22, kernel 6.8.0-136-generic             |

Avalie explicitamente se a GT 740M é utilizável pelo Ollama hoje (driver, arquitetura,
suporte CUDA atual, compatibilidade com a versão atual do Ollama). Não presuma
aceleração útil só por existir uma GPU NVIDIA.

INFRAESTRUTURA EXISTENTE (preservar, não alterar sem necessidade):

../homelab
├── infra/automation/n8n
├── infra/databases/{mongodb,mysql}
├── infra/dns/pihole
├── infra/ia/ollama
├── infra/management/portainer
└── infra/proxy/nginx

Serviços rodando: Nginx, Ollama, Open WebUI, MySQL, Pi-hole, n8n, Portainer.

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
   listada na seção 9 do meu levantamento original (ler múltiplos arquivos, editar,
   executar comandos, Git diff, etc.), diga quem fornece: VSCode / Extensão / Ollama /
   Modelo.
3. Se o Nginx é necessário no caminho VSCode → Ollama, ou se acesso direto (rede
   Docker/host) é preferível — avalie latência, streaming, timeout, segurança,
   manutenção.
4. Modelos Ollama atualmente adequados a este hardware (CPU-only provavelmente,
   confirme se a GT 740M ajuda), avaliando RAM necessária, contexto, velocidade
   esperada, qualidade para código — para 3 usos possíveis: chat/agent principal,
   autocomplete (se fizer sentido), e análise/documentação (se precisar de modelo
   diferente).
5. Analise minha configuração atual do docker-compose do Ollama (cole aqui) parâmetro
   por parâmetro: manter / alterar / remover / irrelevante — com justificativa técnica
   ligada a este hardware específico, não "boa prática" genérica.

Não proponha ainda a arquitetura final. Apenas diagnóstico e opções levantadas com
fontes.
```

---

## FASE 2 — Decisão Arquitetural e Configuração Final

```text
Com base no diagnóstico da Fase 1 [cole aqui ou referencie a resposta anterior],
usando o CONTEXTO E REGRAS GERAIS, decida agora a arquitetura final.

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
Com base nas Fases 1 e 2 [cole ou referencie], usando o CONTEXTO E REGRAS GERAIS,
finalize a entrega.

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