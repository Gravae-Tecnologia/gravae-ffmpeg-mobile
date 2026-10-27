#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

require_command git
prepare_directories

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
  git clone --filter=blob:none "$FFMPEG_KIT_REPOSITORY" "$SOURCE_DIR"
fi

git -C "$SOURCE_DIR" fetch --depth=1 origin "$FFMPEG_KIT_COMMIT"
git -C "$SOURCE_DIR" checkout --detach --force "$FFMPEG_KIT_COMMIT"
git -C "$SOURCE_DIR" clean -ffdqx

mkdir -p "$SOURCE_DIR/src"
if [[ ! -d "$SOURCE_DIR/src/ffmpeg/.git" ]]; then
  git clone --depth=1 --branch "$FFMPEG_SOURCE_TAG" \
    "$FFMPEG_SOURCE_REPOSITORY" "$SOURCE_DIR/src/ffmpeg"
else
  git -C "$SOURCE_DIR/src/ffmpeg" fetch --depth=1 origin \
    "refs/tags/$FFMPEG_SOURCE_TAG:refs/tags/$FFMPEG_SOURCE_TAG"
  git -C "$SOURCE_DIR/src/ffmpeg" checkout --detach --force "$FFMPEG_SOURCE_TAG"
  git -C "$SOURCE_DIR/src/ffmpeg" clean -ffdqx
fi

"$SCRIPT_DIR/patch-tls-hostname.sh" "$SOURCE_DIR/src/ffmpeg"
"$SCRIPT_DIR/patch-clang-bitfields.sh" "$SOURCE_DIR/src/ffmpeg"
"$SCRIPT_DIR/patch-android-16kb.sh" "$SOURCE_DIR"
"$SCRIPT_DIR/patch-libpng-xcode.sh" "$SOURCE_DIR"
"$SCRIPT_DIR/patch-libiconv-docs.sh" "$SOURCE_DIR"
"$SCRIPT_DIR/patch-libuuid-clang.sh" "$SOURCE_DIR"

actual_commit="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
if [[ "$actual_commit" != "$FFMPEG_KIT_COMMIT" ]]; then
  echo "[ffmpeg-mobile] Commit inesperado: $actual_commit" >&2
  exit 1
fi

echo "[ffmpeg-mobile] Fontes preparadas em $SOURCE_DIR"
