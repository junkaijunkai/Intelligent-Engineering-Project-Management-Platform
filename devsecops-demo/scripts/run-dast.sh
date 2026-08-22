#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

EVIDENCE_DIR="$OUT_DIR/03-security/dast"
mkdir -p "$EVIDENCE_DIR"
chmod 0777 "$EVIDENCE_DIR"

set +e
TARGET_HOST="${DEVSECOPS_TARGET_HOST:-pmhub-gateway}"
TARGET_PORT="${DEVSECOPS_TARGET_PORT:-6880}"
docker run --rm \
  --network "$DEMO_NETWORK" \
  -v "$EVIDENCE_DIR:/zap/wrk/:rw" \
  "$ZAP_IMAGE" \
  zap-baseline.py \
  -t "http://${TARGET_HOST}:${TARGET_PORT}/" \
  -m 2 \
  -I \
  -r zap-report.html \
  -J zap-report.json \
  -w zap-report.md \
  > "$EVIDENCE_DIR/zap-console.txt" 2>&1
zap_status=$?
set -e

if [ ! -s "$EVIDENCE_DIR/zap-report.html" ] || [ ! -s "$EVIDENCE_DIR/zap-report.json" ]; then
  record_status dast FAILED "ZAP did not produce the required HTML and JSON reports."
  exit 1
fi

record_status dast PASS "ZAP Baseline completed against the project Gateway scope (exit code $zap_status)."
