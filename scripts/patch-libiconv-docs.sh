#!/usr/bin/env bash
set -euo pipefail

ffmpeg_kit_dir="${1:?Informe a pasta do FFmpegKit}"
target="$ffmpeg_kit_dir/scripts/android/libiconv.sh"
patch_file="$(cd "$(dirname "$0")/.." && pwd)/patches/ffmpeg-kit-libiconv-docs.patch"

if grep -q 'does not ship generated HTML manuals' "$target"; then
  echo "[ffmpeg-mobile] Patch libiconv/docs já aplicado."
  exit 0
fi

patch -d "$ffmpeg_kit_dir" -p1 < "$patch_file"

if ! grep -q 'does not ship generated HTML manuals' "$target"; then
  echo "[ffmpeg-mobile] Não foi possível aplicar o patch libiconv/docs." >&2
  exit 1
fi
