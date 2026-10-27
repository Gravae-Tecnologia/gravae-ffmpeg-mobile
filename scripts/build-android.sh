#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

require_command git
require_command java
require_command perl

if [[ -z "${ANDROID_SDK_ROOT:-}" || -z "${ANDROID_NDK_ROOT:-}" ]]; then
  echo "[ffmpeg-mobile] ANDROID_SDK_ROOT e ANDROID_NDK_ROOT são obrigatórios." >&2
  exit 1
fi

"$SCRIPT_DIR/prepare-source.sh"

detected_ndk="$(sed -n 's/^Pkg.Revision *= *//p' "$ANDROID_NDK_ROOT/source.properties")"
if [[ "$detected_ndk" != "$ANDROID_NDK_VERSION" ]]; then
  echo "[ffmpeg-mobile] NDK $ANDROID_NDK_VERSION esperado; encontrado $detected_ndk." >&2
  exit 1
fi

cd "$SOURCE_DIR"
./android.sh \
  --api-level="$ANDROID_API_LEVEL" \
  --disable-arm-v7a-neon \
  --disable-x86 \
  --enable-android-media-codec \
  --enable-android-zlib \
  --enable-openssl \
  --no-link-time-optimization

"$SCRIPT_DIR/package-android.sh"
"$SCRIPT_DIR/validate-license.sh" "$SOURCE_DIR/build.log"
"$SCRIPT_DIR/validate-android.sh" "$DIST_DIR/gravae-ffmpeg-android-$FFMPEG_MOBILE_VERSION.tar.gz"
"$SCRIPT_DIR/package-sources.sh" --from-existing
