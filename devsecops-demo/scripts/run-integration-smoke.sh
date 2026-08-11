#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

EVIDENCE_DIR="$OUT_DIR/01-testing/integration"
mkdir -p "$EVIDENCE_DIR"

headers="$EVIDENCE_DIR/http-response-headers.txt"
body="$TMP_DIR/frontend-index.html"
start_ms=$(python3 -c 'import time; print(int(time.time() * 1000))')
status=$(curl --silent --show-error --dump-header "$headers" --output "$body" --write-out '%{http_code}' http://127.0.0.1:18080/)
end_ms=$(python3 -c 'import time; print(int(time.time() * 1000))')
duration_ms=$((end_ms - start_ms))

failures=0
[ "$status" = "200" ] || failures=$((failures + 1))
grep -q 'id="app"' "$body" || failures=$((failures + 1))

STATUS_CODE="$status" DURATION_MS="$duration_ms" FAILURES="$failures" python3 - <<'PY'
import json, os
from pathlib import Path
out = Path(os.environ["OUT_DIR"]) / "01-testing/integration"
failures = int(os.environ["FAILURES"])
duration = int(os.environ["DURATION_MS"])
summary = {
    "test": "Frontend integration smoke",
    "status": "PASS" if failures == 0 else "FAIL",
    "assertions": 2,
    "failures": failures,
    "httpStatus": int(os.environ["STATUS_CODE"]),
    "durationMs": duration,
    "scope": "Static frontend demo container",
}
(out / "integration-summary.json").write_text(json.dumps(summary, indent=2) + "\n")
xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="FrontendIntegrationSmoke" tests="2" failures="{failures}" errors="0" skipped="0" time="{duration / 1000:.3f}">
  <testcase classname="devsecops.demo.FrontendSmoke" name="returnsHttp200" time="{duration / 2000:.3f}">{'<failure message="Expected HTTP 200" />' if os.environ['STATUS_CODE'] != '200' else ''}</testcase>
  <testcase classname="devsecops.demo.FrontendSmoke" name="containsApplicationRoot" time="{duration / 2000:.3f}">{'<failure message="Expected application root" />' if failures and os.environ['STATUS_CODE'] == '200' else ''}</testcase>
</testsuite>
'''
(out / "junit-integration-smoke.xml").write_text(xml)
PY

if [ "$failures" -ne 0 ]; then
  record_status integration FAILED "$failures integration assertions failed."
  exit 1
fi
record_status integration PASS "HTTP 200 and application root assertions passed."
