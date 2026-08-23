#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

if [ "${CI:-false}" = "true" ] && command -v sudo >/dev/null 2>&1; then
  sudo chown -R "$(id -u):$(id -g)" "$OUT_DIR" "$TMP_DIR"
else
  chown -R "$(id -u):$(id -g)" "$OUT_DIR" "$TMP_DIR" 2>/dev/null || true
fi

chmod -R u+rwX "$OUT_DIR" "$TMP_DIR"
record_status artifact-permissions PASS "Evidence artifact ownership and user read/write permissions were normalized."
