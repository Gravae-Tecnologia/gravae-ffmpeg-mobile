#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

if [[ "${1:-}" != "--from-existing" ]]; then
  "$SCRIPT_DIR/prepare-source.sh"
fi

if [[ ! -d "$SOURCE_DIR/.git" || ! -d "$SOURCE_DIR/src/ffmpeg" ]]; then
  echo "[ffmpeg-mobile] Fontes preparadas não encontradas em $SOURCE_DIR." >&2
  exit 1
fi

stage="$WORK_DIR/package-sources"
rm -rf "$stage"
mkdir -p "$stage/build-infrastructure" "$stage/ffmpeg-kit"

git -C "$SOURCE_DIR" archive --format=tar HEAD | tar -xf - -C "$stage/ffmpeg-kit"
cp -R "$SOURCE_DIR/src" "$stage/ffmpeg-kit/src"
cp -R "$ROOT_DIR/config" "$stage/build-infrastructure/config"
cp -R "$ROOT_DIR/patches" "$stage/build-infrastructure/patches"
cp -R "$ROOT_DIR/scripts" "$stage/build-infrastructure/scripts"
cp "$ROOT_DIR/LICENSE" "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$stage/build-infrastructure/"

find "$stage" -type d -name .git -prune -exec rm -rf {} +
mkdir -p "$DIST_DIR"
tar -czf "$DIST_DIR/gravae-ffmpeg-sources-$FFMPEG_MOBILE_VERSION.tar.gz" -C "$stage" .
