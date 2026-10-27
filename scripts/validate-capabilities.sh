#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

platform="${1:?Informe android ou ios}"
if [[ "$platform" != "android" && "$platform" != "ios" ]]; then
  echo "[ffmpeg-mobile] Plataforma inválida para validação: $platform" >&2
  exit 1
fi

components_file="$SOURCE_DIR/src/ffmpeg/config_components.h"
if [[ ! -f "$components_file" ]]; then
  echo "[ffmpeg-mobile] config_components.h não foi gerado pelo FFmpeg." >&2
  exit 1
fi

required_components=(
  AAC_ENCODER
  SCALE_FILTER CROP_FILTER PAD_FILTER FPS_FILTER SETPTS_FILTER TPAD_FILTER
  TRIM_FILTER ATEMPO_FILTER VOLUME_FILTER APAD_FILTER ATRIM_FILTER AFADE_FILTER
  AFFTDN_FILTER XFADE_FILTER ACROSSFADE_FILTER ADELAY_FILTER AMIX_FILTER
  DRAWBOX_FILTER DRAWTEXT_FILTER TILE_FILTER
  HLS_DEMUXER MOV_DEMUXER MOV_MUXER CONCAT_DEMUXER HTTPS_PROTOCOL
)

if [[ "$platform" == "android" ]]; then
  required_components+=(H264_MEDIACODEC_ENCODER)
  binary_root="$SOURCE_DIR/prebuilt"
  expected_slices=3
  binary_pattern='libavcodec.so'
else
  required_components+=(H264_VIDEOTOOLBOX_ENCODER)
  binary_root="$SOURCE_DIR/prebuilt/bundle-apple-xcframework-ios"
  expected_slices=2
  binary_pattern='libavcodec'
fi

report="$WORK_DIR/capabilities-$platform.txt"
mkdir -p "$WORK_DIR"
: > "$report"
printf 'platform=%s\nffmpeg=%s\nwrapper_commit=%s\n' \
  "$platform" "$FFMPEG_SOURCE_TAG" "$FFMPEG_KIT_COMMIT" >> "$report"

for component in "${required_components[@]}"; do
  if ! grep -Eq "^#define CONFIG_${component} 1$" "$components_file"; then
    echo "[ffmpeg-mobile] Capacidade ausente no FFmpeg compilado: CONFIG_$component" >&2
    exit 1
  fi
  printf 'component:%s\n' "$(printf '%s' "$component" | tr '[:upper:]' '[:lower:]')" >> "$report"
done

slice_count="$(find "$binary_root" -type f -name "$binary_pattern" | wc -l | tr -d ' ')"
if [[ "$slice_count" -ne "$expected_slices" ]]; then
  echo "[ffmpeg-mobile] Esperadas $expected_slices slices de $binary_pattern; encontradas $slice_count." >&2
  exit 1
fi

while IFS= read -r binary; do
  if [[ ! -s "$binary" ]]; then
    echo "[ffmpeg-mobile] Binário nativo vazio: $binary" >&2
    exit 1
  fi
  printf 'binary:%s\n' "${binary#"$SOURCE_DIR/prebuilt/"}" >> "$report"
done < <(find "$binary_root" -type f -name "$binary_pattern" | sort)

sort -u -o "$report" "$report"
echo "[ffmpeg-mobile] Capacidades e $slice_count slices reais de $platform validadas."
