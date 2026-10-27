#!/usr/bin/env bash
set -euo pipefail

ffmpeg_dir="${1:?Informe a pasta do FFmpeg}"
target="$ffmpeg_dir/fftools/ffmpeg_mux_init.c"
patch_file="$(cd "$(dirname "$0")/.." && pwd)/patches/ffmpeg-6.0-clang-bitfields.patch"
ffmpeg_kit_dir="$(cd "$ffmpeg_dir/../.." && pwd)"
wrapper_target="$ffmpeg_kit_dir/android/ffmpeg-kit-android-lib/src/main/cpp/fftools_ffmpeg_mux_init.c"
wrapper_patch_file="$(cd "$(dirname "$0")/.." && pwd)/patches/ffmpeg-kit-android-clang-bitfields.patch"

if grep -q 'unsigned           pre_only:1' "$target" &&
  grep -q 'unsigned           pre_only:1' "$wrapper_target"; then
  echo "[ffmpeg-mobile] Patch Clang/bitfields já aplicado."
  exit 0
fi

patch -d "$ffmpeg_dir" -p1 < "$patch_file"
patch -d "$ffmpeg_kit_dir" -p1 < "$wrapper_patch_file"

if ! grep -q 'unsigned           pre_only:1' "$target" ||
  ! grep -q 'unsigned           pre_only:1' "$wrapper_target"; then
  echo "[ffmpeg-mobile] Não foi possível aplicar o patch Clang/bitfields." >&2
  exit 1
fi
