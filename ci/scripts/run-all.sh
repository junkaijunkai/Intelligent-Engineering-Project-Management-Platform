#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export DEVSECOPS_ARTIFACT_MANIFEST="artifact-manifest-project-ci.txt"

trap 'bash "$SCRIPT_DIR/cleanup.sh"' EXIT

bash "$SCRIPT_DIR/preflight.sh"
for stage in \
  run-unit-tests.sh \
  run-sast.sh \
  run-full-project-runtime.sh; do
  bash "$SCRIPT_DIR/$stage" || true
done
bash "$SCRIPT_DIR/generate-compliance.sh"
bash "$SCRIPT_DIR/sanitize-artifacts.sh"
bash "$SCRIPT_DIR/verify-artifacts.sh"
