#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

archive="${1:?Informe o pacote Android}"
require_command unzip

stage="$WORK_DIR/validate-android"
rm -rf "$stage"
mkdir -p "$stage/package" "$stage/aar"
tar -xzf "$archive" -C "$stage/package"
aar="$(find "$stage/package" -type f -name '*.aar' -print -quit)"
unzip -q "$aar" -d "$stage/aar"

for abi in armeabi-v7a arm64-v8a x86_64; do
  if [[ ! -d "$stage/aar/jni/$abi" ]]; then
    echo "[ffmpeg-mobile] ABI ausente no AAR: $abi" >&2
    exit 1
  fi
done

readelf_bin="$(find "${ANDROID_NDK_ROOT:?}" -type f -name llvm-readelf -perm -111 -print -quit)"
if [[ -z "$readelf_bin" ]]; then
  echo "[ffmpeg-mobile] llvm-readelf não encontrado no NDK." >&2
  exit 1
fi

while IFS= read -r library; do
  if "$readelf_bin" -lW "$library" | awk '/ LOAD / { if ($NF != "0x4000" && $NF != "0x10000") exit 1 }'; then
    :
  else
    echo "[ffmpeg-mobile] Biblioteca sem alinhamento flexível de 16 KB: $library" >&2
    exit 1
  fi
done < <(find "$stage/aar/jni" -type f -name '*.so' -print)

echo "[ffmpeg-mobile] AAR e alinhamento Android validados."
