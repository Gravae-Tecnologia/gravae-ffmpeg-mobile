#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/config/build.env"

WORK_DIR="${FFMPEG_MOBILE_WORK_DIR:-$ROOT_DIR/.work}"
SOURCE_DIR="$WORK_DIR/ffmpeg-kit"
DIST_DIR="${FFMPEG_MOBILE_DIST_DIR:-$ROOT_DIR/dist}"

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[ffmpeg-mobile] Comando obrigatório ausente: $1" >&2
    exit 1
  }
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

prepare_directories() {
  mkdir -p "$WORK_DIR" "$DIST_DIR"
}
