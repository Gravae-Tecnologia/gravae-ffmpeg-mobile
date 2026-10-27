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
binary_count=0
while IFS= read -r framework; do
  count=$((count + 1))
  info="$framework/Info.plist"
  plutil -lint "$info" >/dev/null
  description="$(plutil -convert json -o - "$info")"
  if [[ "$description" != *'ios-arm64'* || "$description" != *'ios-arm64-simulator'* ]]; then
    echo "[ffmpeg-mobile] Slice de aparelho ou simulador ausente em $framework" >&2
    exit 1
  fi
  while IFS= read -r slice; do
    binary_count=$((binary_count + 1))
    if ! file "$slice" | grep -q 'dynamically linked shared library'; then
      echo "[ffmpeg-mobile] Framework iOS não é dinâmico/relinkável: $slice" >&2
      exit 1
    fi
  done < <(
    find "$framework" -type d -name '*.framework' | while IFS= read -r slice_framework; do
      slice_name="$(basename "$slice_framework" .framework)"
      [[ -f "$slice_framework/$slice_name" ]] && printf '%s\n' "$slice_framework/$slice_name"
    done
  )
done < <(find "$stage/ios/Frameworks" -maxdepth 1 -type d -name '*.xcframework' -print)

if [[ "$count" -eq 0 ]]; then
  echo "[ffmpeg-mobile] Nenhum XCFramework encontrado." >&2
  exit 1
fi

if [[ "$binary_count" -lt $((count * 2)) ]]; then
  echo "[ffmpeg-mobile] Slices binárias iOS incompletas: $binary_count para $count XCFrameworks." >&2
  exit 1
fi

echo "[ffmpeg-mobile] $count XCFrameworks e $binary_count slices dinâmicas iOS validados."
