#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

EVIDENCE_DIR="$OUT_DIR/03-security/sast"
mkdir -p "$EVIDENCE_DIR"

scan_paths=(
  /workspace/pmhub-gateway
  /workspace/pmhub-auth
  /workspace/pmhub-api
  /workspace/pmhub-base
  /workspace/pmhub-modules
  /workspace/pmhub-ui/src
)

docker run --rm \
  -v "$ROOT_DIR:/workspace:ro" \
  -v "$EVIDENCE_DIR:/evidence" \
  "$SEMGREP_IMAGE" \
  semgrep scan \
  --config /workspace/ci/config/semgrep-rules.yml \
  --exclude pmhub-boot \
  --exclude target \
  --exclude node_modules \
  --exclude dist \
  --exclude devsecops-demo/out \
  --json --output /evidence/semgrep.json \
  "${scan_paths[@]}" \
  > "$EVIDENCE_DIR/semgrep-console.txt" 2>&1

docker run --rm \
  -v "$ROOT_DIR:/workspace:ro" \
  -v "$EVIDENCE_DIR:/evidence" \
  "$SEMGREP_IMAGE" \
  semgrep scan \
  --config /workspace/ci/config/semgrep-rules.yml \
  --exclude pmhub-boot \
  --exclude target \
  --exclude node_modules \
  --exclude dist \
  --exclude devsecops-demo/out \
  --sarif --output /evidence/semgrep.sarif \
  "${scan_paths[@]}" \
  >/dev/null 2>&1

test -s "$EVIDENCE_DIR/semgrep.json"

export EVIDENCE_DIR
error_findings=$(python3 - <<'PY'
import json
import os
from pathlib import Path

report = Path(os.environ["EVIDENCE_DIR"]) / "semgrep.json"
data = json.loads(report.read_text(encoding="utf-8"))
count = sum(
    1
    for item in data.get("results", [])
    if item.get("extra", {}).get("severity") == "ERROR"
)
print(count)
PY
)

if [ "$error_findings" -gt 0 ]; then
  record_status sast FAILED "Semgrep completed with $error_findings ERROR severity findings."
  exit 1
fi

record_status sast PASS "Semgrep completed; WARNING and INFO findings were retained without failing the evidence workflow."
