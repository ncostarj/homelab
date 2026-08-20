#!/usr/bin/env bash
#
# testar-latencia.sh
#
# Mede latência real do Ollama local usando as métricas nativas da própria
# API (total_duration, load_duration, prompt_eval_duration, eval_duration),
# não estimativas — são os números exatos que o Ollama mede internamente.
#
# Testa dois cenários:
#   1. COLD START — modelo descarregado da RAM, mede o custo de carregar
#   2. WARM — modelo já carregado, mede só o custo de geração
#   3. PROMPT REALISTA — simula o tamanho de prompt que o Cline costuma
#      enviar (system prompt + definições de ferramentas), não um "oi"
#
# Requisitos: curl, jq, bc
#
set -euo pipefail

OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11435}"
MODEL="${1:-qwen3:4b}"
THINK="${2:-false}"   # true | false — controla o modo de raciocínio (Qwen3/DeepSeek-R1 etc.)

ns_para_s() { echo "scale=2; $1 / 1000000000" | bc; }

# IMPORTANTE: usar /api/chat, não /api/generate.
# /api/generate é completação de texto bruto e NÃO aplica o template de
# conversa do modelo — em modelos instruction-tuned (como o Qwen3) isso pode
# fazer o modelo perder a instrução e "continuar o texto" de forma
# incoerente, além de não respeitar corretamente o parâmetro `think`
# (que é resolvido no nível do template de chat).
chamar() {
  local conteudo="$1"
  curl -s "$OLLAMA_URL/api/chat" -d "$(jq -n \
    --arg model "$MODEL" --arg conteudo "$conteudo" --argjson think "$THINK" \
    '{model: $model, messages: [{role: "user", content: $conteudo}], think: $think, stream: false}')"
}

relatorio() {
  local resposta="$1" rotulo="$2"
  local total load prompt_eval eval_dur eval_count prompt_count

  total=$(echo "$resposta" | jq -r '.total_duration // 0')
  load=$(echo "$resposta" | jq -r '.load_duration // 0')
  prompt_eval=$(echo "$resposta" | jq -r '.prompt_eval_duration // 0')
  eval_dur=$(echo "$resposta" | jq -r '.eval_duration // 0')
  eval_count=$(echo "$resposta" | jq -r '.eval_count // 0')
  prompt_count=$(echo "$resposta" | jq -r '.prompt_eval_count // 0')

  local tok_s="N/A"
  if [[ "$eval_dur" != "0" && "$eval_count" != "0" ]]; then
    tok_s=$(echo "scale=2; $eval_count / ($eval_dur / 1000000000)" | bc)
  fi

  echo "=== $rotulo ==="
  echo "  Tempo total:              $(ns_para_s "$total")s"
  echo "  Tempo de carga do modelo: $(ns_para_s "$load")s"
  echo "  Tempo de leitura do prompt: $(ns_para_s "$prompt_eval")s  (${prompt_count} tokens de prompt)"
  echo "  Tempo de geração:         $(ns_para_s "$eval_dur")s  (${eval_count} tokens gerados)"
  echo "  Velocidade de geração:    ${tok_s} tokens/s"
  echo
}

echo "Modelo: $MODEL"
echo "Endpoint: $OLLAMA_URL"
echo "Thinking mode: $THINK"
echo

# --- Cenário 1: cold start (força descarregar o modelo antes) ---
echo "[1/3] Descarregando modelo para medir cold start..."
curl -s "$OLLAMA_URL/api/chat" -d "$(jq -n --arg model "$MODEL" '{model: $model, messages: [], keep_alive: 0}')" > /dev/null
sleep 2

r1=$(chamar "Responda apenas: OK")
relatorio "$r1" "COLD START (modelo descarregado antes)"

# --- Cenário 2: warm (modelo já carregado pelo teste anterior) ---
r2=$(chamar "Responda apenas: OK")
relatorio "$r2" "WARM (modelo já carregado)"

# --- Cenário 3: prompt realista, tamanho parecido com o que o Cline envia ---
prompt_realista='Você é um assistente de programação. Analise o código abaixo e sugira uma pequena melhoria, com uma frase de explicação.

```python
def calcular_total(itens):
    total = 0
    for i in itens:
        total = total + i["preco"] * i["quantidade"]
    return total
```

Ferramentas disponíveis: read_file, write_file, run_command, list_files, search_code.
Responda de forma objetiva.'

r3=$(chamar "$prompt_realista")
relatorio "$r3" "PROMPT REALISTA (~tamanho de contexto do Cline)"

echo "Referência: o timeout padrão do Cline é 30s. Compare o 'Tempo total' de"
echo "cada cenário acima com isso para saber se precisa aumentar o timeout"
echo "e por quanto (recomendação anterior: 120-180s neste hardware)."
echo
echo "Uso: ./testar-latencia.sh <modelo> <think:true|false>"
echo "Ex.: ./testar-latencia.sh qwen3:4b false"