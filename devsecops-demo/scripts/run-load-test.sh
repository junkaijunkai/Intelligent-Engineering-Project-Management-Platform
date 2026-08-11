#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

EVIDENCE_DIR="$OUT_DIR/01-testing/load"
mkdir -p "$EVIDENCE_DIR"

docker run --rm \
  --network "$DEMO_NETWORK" \
  -e TARGET_URL="http://$FRONTEND_CONTAINER/health" \
  -v "$DEMO_DIR/load:/scripts:ro" \
  -v "$EVIDENCE_DIR:/evidence" \
  "$K6_IMAGE" run /scripts/k6-smoke.js \
  > "$EVIDENCE_DIR/k6-console.txt" 2>&1

test -s "$EVIDENCE_DIR/k6-summary.json"
record_status load PASS "k6 completed with 5 virtual users for 30 seconds and all thresholds passed."
