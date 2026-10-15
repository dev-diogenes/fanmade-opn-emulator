#!/usr/bin/env bash
# Roda os testes GUT em modo headless.
# Uso: GODOT=/caminho/para/godot_console.exe tools/rodar_testes.sh
set -euo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/../game"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json
