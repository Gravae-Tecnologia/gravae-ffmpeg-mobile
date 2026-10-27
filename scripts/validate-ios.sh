#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

archive="${1:?Informe o pacote iOS}"
require_command plutil

stage="$WORK_DIR/validate-ios"
rm -rf "$stage"
mkdir -p "$stage"
tar -xzf "$archive" -C "$stage"

count=0
while IFS= read -r framework; do
  count=$((count + 1))
  info="$framework/Info.plist"
  plutil -lint "$info" >/dev/null
  description="$(plutil -convert json -o - "$info")"
  if [[ "$description" != *'ios-arm64'* || "$description" != *'ios-arm64-simulator'* ]]; then
    echo "[ffmpeg-mobile] Slice de aparelho ou simulador ausente em $framework" >&2
    exit 1
  fi
done < <(find "$stage/ios/Frameworks" -maxdepth 1 -type d -name '*.xcframework' -print)

if [[ "$count" -eq 0 ]]; then
  echo "[ffmpeg-mobile] Nenhum XCFramework encontrado." >&2
  exit 1
fi

echo "[ffmpeg-mobile] XCFrameworks iOS validados."
