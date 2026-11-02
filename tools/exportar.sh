#!/usr/bin/env bash
# Build de playtest para Windows (Sprint 01, docs/78).
# Uso: GODOT=/caminho/para/godot_console.exe tools/exportar.sh
# Precisa dos modelos de exportação do Godot da MESMA versão do editor (Editor → Gerenciar
# Modelos de Exportação). O export_presets.cfg fica fora do git; se não existir, este script
# cria o preset padrão. A build sai em builds/ (também fora do git).
set -euo pipefail
GODOT="${GODOT:-godot}"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ/game"
if [ ! -f export_presets.cfg ]; then
  cat > export_presets.cfg <<'CFG'
[preset.0]

name="Windows Desktop"
platform="Windows Desktop"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter="*.json, *.txt, *.md"
exclude_filter="tests/*, addons/gut/*, tmp_render/*"
export_path="../builds/Membrana.exe"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.0.options]

custom_template/debug=""
custom_template/release=""
debug/export_console_wrapper=1
binary_format/embed_pck=true
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
binary_format/architecture="x86_64"
application/product_name="Membrana"
application/file_description="Membrana: um jogo inspirado no sistema de Ordem Paranormal (fanmade, não oficial)"
CFG
  echo "Criei game/export_presets.cfg (preset padrão)."
fi
mkdir -p "$RAIZ/builds"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release "Windows Desktop" "$RAIZ/builds/Membrana.exe"
ls -la "$RAIZ/builds"
# Teste de fumaça: a build abre sem o projeto ao lado e fecha sozinha
cd "$RAIZ/builds"
if timeout 60 ./Membrana.console.exe --headless --quit-after 120 >fumaca.txt 2>&1 || timeout 60 ./Membrana.exe --headless --quit-after 120 >fumaca.txt 2>&1; then
  if grep -q "SCRIPT ERROR\|Parse Error" fumaca.txt; then
    echo "FUMAÇA: a build abriu com erros de script (veja builds/fumaca.txt)."
    exit 1
  fi
  echo "FUMAÇA OK: a build abriu e fechou sem erro de script."
else
  echo "FUMAÇA FALHOU (veja builds/fumaca.txt)."
  exit 1
fi
