#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

EVIDENCE_DIR="$OUT_DIR/01-testing/load"
mkdir -p "$EVIDENCE_DIR"

TARGET_HOST="${DEVSECOPS_TARGET_HOST:-pmhub-gateway}"
TARGET_PORT="${DEVSECOPS_TARGET_PORT:-6880}"
target_url="http://${TARGET_HOST}:${TARGET_PORT}/actuator/health"

set +e
docker run --rm \
  --network "$DEMO_NETWORK" \
  -e TARGET_URL="$target_url" \
  -v "$DEMO_DIR/load:/scripts:ro" \
  -v "$EVIDENCE_DIR:/evidence" \
  "$K6_IMAGE" run /scripts/k6-smoke.js \
  > "$EVIDENCE_DIR/k6-console.txt" 2>&1
k6_status=$?
set -e

if [ ! -s "$EVIDENCE_DIR/k6-summary.json" ]; then
  K6_STATUS="$k6_status" K6_TARGET_URL="$target_url" python3 - <<'PY'
import json, os
from pathlib import Path
out = Path(os.environ["OUT_DIR"]) / "01-testing/load"
summary = {
    "status": "FAILED",
    "tool": "k6",
    "exitCode": int(os.environ["K6_STATUS"]),
    "targetUrl": os.environ["K6_TARGET_URL"],
    "consoleLog": "01-testing/load/k6-console.txt",
    "detail": "k6 did not produce its native summary; see console log for the original failure.",
}
(out / "k6-summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
PY
fi

if [ "$k6_status" -eq 0 ]; then
  record_status load PASS "k6 completed with 5 virtual users for 30 seconds and all thresholds passed."
else
  record_status load FAILED "k6 exited with code $k6_status; native report and console log were retained."
fi

exit 0
