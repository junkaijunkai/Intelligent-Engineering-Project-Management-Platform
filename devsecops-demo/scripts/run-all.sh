#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

trap 'bash "$SCRIPT_DIR/cleanup.sh"' EXIT

bash "$SCRIPT_DIR/preflight.sh"
for stage in \
  run-unit-tests.sh \
  run-container-evidence.sh \
  run-integration-smoke.sh \
  run-load-test.sh \
  run-sast.sh \
  run-trivy.sh \
  run-gateway-demo.sh \
  run-dast.sh; do
  bash "$SCRIPT_DIR/$stage" || true
done
bash "$SCRIPT_DIR/generate-compliance.sh"
bash "$SCRIPT_DIR/generate-dashboard.sh"
bash "$SCRIPT_DIR/sanitize-artifacts.sh"
bash "$SCRIPT_DIR/verify-artifacts.sh"
