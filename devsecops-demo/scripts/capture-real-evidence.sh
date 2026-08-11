#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

CAPTURE_DIR="$OUT_DIR/06-presentation/raw-screenshots"
EXCERPT_DIR="$OUT_DIR/06-presentation/raw-evidence-excerpts"
mkdir -p "$CAPTURE_DIR" "$EXCERPT_DIR"

if command -v google-chrome >/dev/null 2>&1; then
  CHROME_BIN="$(command -v google-chrome)"
elif command -v chromium >/dev/null 2>&1; then
  CHROME_BIN="$(command -v chromium)"
elif [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
  CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
else
  record_status evidence-capture FAILED "Chrome or Chromium is required for evidence screenshots."
  exit 1
fi

# These excerpts are copied verbatim from full retained artifacts. They keep the
# meaningful tool output visible at presentation scale without inventing data.
tail -80 "$OUT_DIR/01-testing/load/k6-console.txt" > "$EXCERPT_DIR/k6-result.txt"
sed -n '/Scan Status/,$p' "$OUT_DIR/03-security/sast/semgrep-console.txt" > "$EXCERPT_DIR/semgrep-result.txt"
head -80 "$OUT_DIR/03-security/image/trivy-frontend-table.txt" > "$EXCERPT_DIR/trivy-image-result.txt"
head -100 "$OUT_DIR/04-compliance/iac/trivy-iac-table.txt" > "$EXCERPT_DIR/trivy-iac-result.txt"
tail -85 "$OUT_DIR/03-security/dast/zap-console.txt" > "$EXCERPT_DIR/zap-result.txt"
head -35 "$OUT_DIR/04-compliance/git/git-audit-trail.txt" > "$EXCERPT_DIR/git-audit-result.txt"
{
  cat "$OUT_DIR/02-container/frontend-docker-ps.txt"
  printf '\nHealth response\n'
  cat "$OUT_DIR/02-container/frontend-health.json"
  printf '\nContainer logs\n'
  tail -25 "$OUT_DIR/02-container/frontend-logs.txt"
} > "$EXCERPT_DIR/container-runtime-result.txt"

capture() {
  local source="$1"
  local output="$2"
  local profile="$TMP_DIR/chrome-evidence-${output%.png}"
  mkdir -p "$profile"
  "$CHROME_BIN" \
    --headless \
    --disable-gpu \
    --disable-dev-shm-usage \
    --disable-crash-reporter \
    --disable-background-networking \
    --no-first-run \
    --no-default-browser-check \
    --hide-scrollbars \
    --no-sandbox \
    --user-data-dir="$profile" \
    --force-device-scale-factor=1 \
    --window-size=1400,900 \
    --screenshot="$CAPTURE_DIR/$output" \
    "file://$source" >/dev/null 2>&1
}

capture "$OUT_DIR/01-testing/unit/jacoco/pmhub-base__pmhub-base-core/index.html" "02-unit-jacoco-report.png"
capture "$OUT_DIR/01-testing/integration/junit-integration-smoke.xml" "03-integration-junit-result.png"
capture "$EXCERPT_DIR/k6-result.txt" "04-load-k6-result.png"
capture "$EXCERPT_DIR/container-runtime-result.txt" "05-container-runtime-result.png"
capture "$EXCERPT_DIR/semgrep-result.txt" "06-sast-semgrep-result.png"
capture "$EXCERPT_DIR/trivy-image-result.txt" "07-image-trivy-result.png"
capture "$OUT_DIR/03-security/dast/zap-report.html" "08-dast-zap-report.png"
capture "$EXCERPT_DIR/zap-result.txt" "09-dast-zap-console.png"
capture "$EXCERPT_DIR/trivy-iac-result.txt" "10-iac-trivy-result.png"
capture "$EXCERPT_DIR/git-audit-result.txt" "11-git-audit-trail.png"
capture "$OUT_DIR/04-compliance/gdpr/gdpr-assessment-mapping.html" "12-gdpr-evidence-map.png"
capture "$OUT_DIR/05-vulnerability/remediation-and-rescan.html" "13-remediation-rescan.png"

record_status evidence-capture PASS "Twelve screenshots were rendered from retained raw reports and logs."
