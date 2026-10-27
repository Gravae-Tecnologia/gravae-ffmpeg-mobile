#!/usr/bin/env bash
set -euo pipefail

ffmpeg_kit_dir="${1:?Informe a pasta do FFmpegKit}"
target="$ffmpeg_kit_dir/scripts/function-android.sh"

if ! grep -q 'max-page-size=16384' "$target"; then
  perl -0pi -e 's/-Wl,--hash-style=both -Wl,--exclude-libs,libgcc\.a/-Wl,-z,max-page-size=16384 -Wl,--hash-style=both -Wl,--exclude-libs,libgcc.a/g' "$target"
  perl -0pi -e 's/^APP_LDFLAGS := -Wl,--hash-style=both/APP_LDFLAGS := -Wl,-z,max-page-size=16384 -Wl,--hash-style=both/mg' "$target"
fi

matches="$(grep -c 'max-page-size=16384' "$target" || true)"
if [[ "$matches" -lt 2 ]]; then
  echo "[ffmpeg-mobile] Não foi possível aplicar integralmente o alinhamento de 16 KB." >&2
  exit 1
fi
