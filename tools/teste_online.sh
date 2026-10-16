#!/usr/bin/env bash
# Teste de fumaça online (Fase 8.2): um host e um cliente, em dois processos do Godot sem
# janela, jogam a mesma missão pelas telas de verdade, cada um na vez dos próprios agentes.
# No fim, o hash da missão precisa ser igual nos dois.
# Uso: GODOT=/caminho/para/godot_console.exe tools/teste_online.sh [semente] [tarde]
# Com "tarde", o cliente entra no meio da missão (recebe o checkpoint e refaz os comandos).
set -uo pipefail
GODOT="${GODOT:-godot}"
SEMENTE="${1:-7}"
TARDE=0
[ "${2:-}" = "tarde" ] && TARDE=1
PORTA=$((20000 + RANDOM % 20000))
cd "$(dirname "$0")/../game"
SAIDA="$(mktemp -d)"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . res://tests/rede/robo_online.tscn -- --papel=host --porta=$PORTA --semente=$SEMENTE --tarde=$TARDE >"$SAIDA/host.txt" 2>&1 &
HOST=$!
"$GODOT" --headless --path . res://tests/rede/robo_online.tscn -- --papel=cliente --porta=$PORTA --semente=$SEMENTE --tarde=$TARDE >"$SAIDA/cliente.txt" 2>&1 &
CLIENTE=$!
( sleep 300; kill $HOST $CLIENTE 2>/dev/null ) >/dev/null 2>&1 &
VIGIA=$!
wait $HOST
wait $CLIENTE
kill $VIGIA 2>/dev/null
grep -h "ROBO\|SCRIPT ERROR" "$SAIDA/host.txt" "$SAIDA/cliente.txt"
H=$(grep -o "ROBO RESULTADO host hash=[0-9-]*" "$SAIDA/host.txt" | sed 's/.*hash=//')
C=$(grep -o "ROBO RESULTADO cliente hash=[0-9-]*" "$SAIDA/cliente.txt" | sed 's/.*hash=//')
if [ -n "$H" ] && [ "$H" = "$C" ]; then
  echo "OK: host e cliente terminaram a missão com o mesmo estado ($H)."
  exit 0
fi
echo "FALHOU: hash do host '$H', do cliente '$C'. Saídas em $SAIDA"
exit 1
