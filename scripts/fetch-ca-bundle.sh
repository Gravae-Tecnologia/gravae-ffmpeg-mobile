#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

require_command curl
prepare_directories

destination="$WORK_DIR/cacert.pem"
checksum_file="$WORK_DIR/cacert.pem.sha256"
curl --fail --silent --show-error --location https://curl.se/ca/cacert.pem --output "$destination"
curl --fail --silent --show-error --location https://curl.se/ca/cacert.pem.sha256 --output "$checksum_file"
expected="$(awk '{print $1}' "$checksum_file")"
actual="$(sha256_file "$destination")"

if [[ "$actual" != "$expected" ]]; then
  echo "[ffmpeg-mobile] Checksum do pacote de CAs divergente." >&2
  exit 1
fi

grep -q 'BEGIN CERTIFICATE' "$destination"
echo "[ffmpeg-mobile] Pacote de CAs Mozilla validado: $actual"
