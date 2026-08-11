#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

IMAGE_DIR="$OUT_DIR/03-security/image"
IAC_DIR="$OUT_DIR/04-compliance/iac"
CACHE_DIR="$TMP_DIR/trivy-cache"
mkdir -p "$IMAGE_DIR" "$IAC_DIR" "$CACHE_DIR"

docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$CACHE_DIR:/root/.cache" \
  -v "$IMAGE_DIR:/evidence" \
  "$TRIVY_IMAGE" image \
  --scanners vuln \
  --format json \
  --output /evidence/trivy-frontend.json \
  "$FRONTEND_IMAGE" \
  > "$IMAGE_DIR/trivy-image-console.txt" 2>&1

docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$CACHE_DIR:/root/.cache" \
  -v "$IMAGE_DIR:/evidence" \
  "$TRIVY_IMAGE" image \
  --skip-db-update \
  --scanners vuln \
  --format table \
  --output /evidence/trivy-frontend-table.txt \
  "$FRONTEND_IMAGE" \
  >/dev/null 2>&1

docker run --rm \
  -v "$CACHE_DIR:/root/.cache" \
  -v "$ROOT_DIR:/workspace:ro" \
  -v "$IAC_DIR:/evidence" \
  "$TRIVY_IMAGE" config \
  --format json \
  --output /evidence/trivy-iac.json \
  /workspace \
  > "$IAC_DIR/trivy-iac-console.txt" 2>&1

docker run --rm \
  -v "$CACHE_DIR:/root/.cache" \
  -v "$ROOT_DIR:/workspace:ro" \
  -v "$IAC_DIR:/evidence" \
  "$TRIVY_IMAGE" config \
  --skip-check-update \
  --format table \
  --output /evidence/trivy-iac-table.txt \
  /workspace \
  >/dev/null 2>&1

test -s "$IMAGE_DIR/trivy-frontend.json"
test -s "$IMAGE_DIR/trivy-frontend-table.txt"
test -s "$IAC_DIR/trivy-iac.json"
test -s "$IAC_DIR/trivy-iac-table.txt"
record_status trivy PASS "Trivy image and infrastructure-as-code scans completed."
