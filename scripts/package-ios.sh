#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

framework_dir="$(find "$SOURCE_DIR/prebuilt" -type d -name 'bundle-apple-xcframework-ios' -print -quit)"
if [[ -z "$framework_dir" ]]; then
  echo "[ffmpeg-mobile] XCFrameworks não encontrados." >&2
  exit 1
fi

stage="$WORK_DIR/package-ios"
"$SCRIPT_DIR/fetch-ca-bundle.sh"
rm -rf "$stage"
mkdir -p "$stage/ios/Frameworks" "$stage/metadata"
find "$framework_dir" -maxdepth 1 -type d -name '*.xcframework' -exec cp -R {} "$stage/ios/Frameworks/" \;
cp "$ROOT_DIR/config/build.env" "$stage/metadata/build.env"
cp "$ROOT_DIR/config/required-capabilities.txt" "$stage/metadata/required-capabilities.txt"
cp "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$stage/metadata/THIRD_PARTY_NOTICES.md"
cp "$WORK_DIR/cacert.pem" "$stage/metadata/cacert.pem"
cp "$SOURCE_DIR/build.log" "$stage/metadata/ios-build.log"

if ! find "$stage/ios/Frameworks" -maxdepth 1 -type d -name '*.xcframework' | grep -q .; then
  echo "[ffmpeg-mobile] Pacote iOS vazio." >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
tar -czf "$DIST_DIR/gravae-ffmpeg-ios-$FFMPEG_MOBILE_VERSION.tar.gz" -C "$stage" .
