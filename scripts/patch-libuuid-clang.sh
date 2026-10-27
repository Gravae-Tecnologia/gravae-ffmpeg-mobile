#!/usr/bin/env bash
set -euo pipefail

ffmpeg_kit_dir="${1:?Informe a pasta do FFmpegKit}"
target="$ffmpeg_kit_dir/scripts/android/libuuid.sh"
patch_file="$(cd "$(dirname "$0")/.." && pwd)/patches/ffmpeg-kit-libuuid-clang.patch"

if grep -q 'Modern Clang rejects the implicit flock declaration' "$target"; then
  echo "[ffmpeg-mobile] Patch libuuid/Clang já aplicado."
  exit 0
fi

patch -d "$ffmpeg_kit_dir" -p1 < "$patch_file"

if ! grep -q 'Modern Clang rejects the implicit flock declaration' "$target"; then
  echo "[ffmpeg-mobile] Não foi possível aplicar o patch libuuid/Clang." >&2
  exit 1
fi
