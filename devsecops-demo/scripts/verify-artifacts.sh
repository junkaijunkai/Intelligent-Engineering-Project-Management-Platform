#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

missing=0
report="$OUT_DIR/00-metadata/artifact-verification.txt"
: > "$report"
while IFS= read -r relative; do
  [ -z "$relative" ] && continue
  if [ -s "$OUT_DIR/$relative" ]; then
    printf 'PASS %s\n' "$relative" >> "$report"
  else
    printf 'FAIL %s\n' "$relative" >> "$report"
    missing=$((missing + 1))
  fi
done < "$DEMO_DIR/config/artifact-manifest.txt"

if [ "$missing" -ne 0 ]; then
  record_status verification FAILED "$missing required artifacts are missing or empty."
  cat "$report"
  exit 1
fi
record_status verification PASS "Every required artifact exists and is non-empty."
cat "$report"
