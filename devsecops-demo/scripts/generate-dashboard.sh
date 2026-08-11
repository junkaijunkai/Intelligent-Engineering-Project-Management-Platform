#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

python3 "$DEMO_DIR/scripts/generate_evidence.py" dashboard
bash "$DEMO_DIR/scripts/sanitize-artifacts.sh"
bash "$DEMO_DIR/scripts/capture-real-evidence.sh"

if command -v google-chrome >/dev/null 2>&1; then
  CHROME_BIN="$(command -v google-chrome)"
elif command -v chromium >/dev/null 2>&1; then
  CHROME_BIN="$(command -v chromium)"
elif [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
  CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
else
  record_status presentation FAILED "Chrome or Chromium is required to render evidence screenshots."
  exit 1
fi

cp "$OUT_DIR/06-presentation/raw-screenshots/02-unit-jacoco-report.png" "$OUT_DIR/06-presentation/01-cicd-evidence.png"
cp "$OUT_DIR/06-presentation/raw-screenshots/05-container-runtime-result.png" "$OUT_DIR/06-presentation/02-container-management.png"
cp "$OUT_DIR/06-presentation/raw-screenshots/08-dast-zap-report.png" "$OUT_DIR/06-presentation/03-vulnerability-assessment.png"
cp "$OUT_DIR/06-presentation/raw-screenshots/10-iac-trivy-result.png" "$OUT_DIR/06-presentation/04-compliance-as-code.png"
cp "$OUT_DIR/06-presentation/raw-screenshots/12-gdpr-evidence-map.png" "$OUT_DIR/06-presentation/05-regulatory-framework.png"

record_status presentation PASS "Dashboard and five tool-native evidence screenshots were generated."
