#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

require_command git
require_command xcodebuild
require_command xcrun

"$SCRIPT_DIR/prepare-source.sh"

cd "$SOURCE_DIR"
./ios.sh \
  --xcframework \
  --target="$IOS_DEPLOYMENT_TARGET" \
  --no-bitcode \
  --disable-armv7 \
  --disable-armv7s \
  --disable-arm64e \
  --disable-i386 \
  --disable-x86-64 \
  --disable-x86-64-mac-catalyst \
  --disable-arm64-mac-catalyst \
  --enable-ios-videotoolbox \
  --enable-ios-audiotoolbox \
  --enable-ios-zlib \
  --enable-ios-bzip2 \
  --enable-openssl

"$SCRIPT_DIR/package-ios.sh"
"$SCRIPT_DIR/validate-license.sh" "$SOURCE_DIR/build.log"
"$SCRIPT_DIR/validate-ios.sh" "$DIST_DIR/gravae-ffmpeg-ios-$FFMPEG_MOBILE_VERSION.tar.gz"
