#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

build_log="${1:?Informe o build.log}"
found=0
while IFS= read -r forbidden; do
  [[ -z "$forbidden" ]] && continue
  if grep -Fqi -- "$forbidden" "$build_log"; then
    echo "[ffmpeg-mobile] Componente proibido encontrado: $forbidden" >&2
    found=1
  fi
done < "$ROOT_DIR/config/forbidden-components.txt"

if [[ "$found" -ne 0 ]]; then
  exit 1
fi

if ! grep -Fq -- '--disable-gpl' "$build_log" && grep -Fq -- '--enable-gpl' "$build_log"; then
  echo "[ffmpeg-mobile] Configuração GPL detectada." >&2
  exit 1
fi

echo "[ffmpeg-mobile] Validação de licença concluída."
