#!/usr/bin/env bash
set -euo pipefail

ffmpeg_dir="${1:?Informe a pasta do FFmpeg}"
target="$ffmpeg_dir/libavformat/tls_openssl.c"

if grep -q 'X509_VERIFY_PARAM_set1_host' "$target"; then
  echo "[ffmpeg-mobile] Patch TLS já aplicado."
  exit 0
fi

patch -d "$ffmpeg_dir" -p1 < "$(cd "$(dirname "$0")/.." && pwd)/patches/ffmpeg-6.0-tls-hostname.patch"
grep -q 'X509_VERIFY_PARAM_set1_host' "$target"
