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
record_status sast PASS "Semgrep completed; findings were retained without failing the evidence workflow."
