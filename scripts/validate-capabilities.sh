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

if [[ "$platform" == "android" ]]; then
  nm_bin="$(find "${ANDROID_NDK_ROOT:?}" -type f -name llvm-nm -perm -111 -print -quit)"
  nm_args=(--defined-only)
  codec_symbol=ff_h264_mediacodec_encoder
else
  nm_bin="$(xcrun --find nm)"
  nm_args=(-gU)
  codec_symbol=ff_h264_videotoolbox_encoder
fi

if [[ -z "$nm_bin" ]]; then
  echo "[ffmpeg-mobile] nm não encontrado para $platform." >&2
  exit 1
fi

mapfile_compat() {
  local array_name="$1"
  shift
  local value
  eval "$array_name=()"
  while IFS= read -r value; do
    [[ -n "$value" ]] || continue
    eval "$array_name+=(\"\$value\")"
  done < <("$@")
}

mapfile_compat codec_archives find "$SOURCE_DIR/prebuilt" -type f -name libavcodec.a -print
mapfile_compat filter_archives find "$SOURCE_DIR/prebuilt" -type f -name libavfilter.a -print
mapfile_compat format_archives find "$SOURCE_DIR/prebuilt" -type f -name libavformat.a -print

if [[ "${#codec_archives[@]}" -eq 0 || "${#filter_archives[@]}" -eq 0 || "${#format_archives[@]}" -eq 0 ]]; then
  echo "[ffmpeg-mobile] Bibliotecas estáticas do FFmpeg não foram encontradas." >&2
  exit 1
fi

required_codec_symbols=("$codec_symbol" ff_aac_encoder)
required_filter_symbols=(
  ff_vf_scale ff_vf_crop ff_vf_pad ff_vf_fps ff_vf_setpts ff_vf_tpad
  ff_vf_trim ff_af_atempo ff_af_volume ff_af_apad ff_af_atrim ff_af_afade
  ff_af_afftdn ff_vf_xfade ff_af_acrossfade ff_af_adelay ff_af_amix
  ff_vf_drawbox ff_vf_drawtext ff_vf_tile
)
required_format_symbols=(ff_hls_demuxer ff_mov_demuxer ff_mov_muxer ff_concat_demuxer ff_https_protocol)

report="$WORK_DIR/capabilities-$platform.txt"
mkdir -p "$WORK_DIR"
: > "$report"
printf 'platform=%s\nffmpeg=%s\nwrapper_commit=%s\n' \
  "$platform" "$FFMPEG_SOURCE_TAG" "$FFMPEG_KIT_COMMIT" >> "$report"

validate_archive() {
  local kind="$1"
  local archive="$2"
  shift 2
  local symbols symbol

  symbols="$($nm_bin "${nm_args[@]}" "$archive" 2>/dev/null || true)"
  for symbol in "$@"; do
    if ! grep -Eq "(^|[[:space:]_])${symbol}([[:space:]]|$)" <<< "$symbols"; then
      echo "[ffmpeg-mobile] $kind ausente em $archive: $symbol" >&2
      exit 1
    fi
    printf '%s:%s\n' "$kind" "${symbol#ff_}" >> "$report"
  done
}

for archive in "${codec_archives[@]}"; do
  validate_archive encoder "$archive" "${required_codec_symbols[@]}"
done
for archive in "${filter_archives[@]}"; do
  validate_archive filter "$archive" "${required_filter_symbols[@]}"
done
for archive in "${format_archives[@]}"; do
  validate_archive format "$archive" "${required_format_symbols[@]}"
done

sort -u -o "$report" "$report"
echo "[ffmpeg-mobile] Capacidades reais de $platform validadas em ${#codec_archives[@]} arquitetura(s)."
