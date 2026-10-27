#!/usr/bin/env bash
set -euo pipefail

ffmpeg_kit_dir="${1:?Informe a pasta do FFmpegKit}"
target="$ffmpeg_kit_dir/scripts/apple/libpng.sh"
patch_file="$(cd "$(dirname "$0")/.." && pwd)/patches/ffmpeg-kit-libpng-xcode.patch"

if grep -q 'Xcode 16.3 removed fp.h' "$target"; then
  echo "[ffmpeg-mobile] Patch libpng/Xcode já aplicado."
  exit 0
fi

patch -d "$ffmpeg_kit_dir" -p1 < "$patch_file"

if ! grep -q 'Xcode 16.3 removed fp.h' "$target"; then
  echo "[ffmpeg-mobile] Não foi possível aplicar o patch libpng/Xcode." >&2
  exit 1
fi
