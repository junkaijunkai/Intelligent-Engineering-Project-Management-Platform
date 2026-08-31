#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

EVIDENCE_DIR="$OUT_DIR/03-security/dast"
mkdir -p "$EVIDENCE_DIR"
chmod 0777 "$EVIDENCE_DIR"

TARGET_HOST="${DEVSECOPS_TARGET_HOST:-pmhub-gateway}"
TARGET_PORT="${DEVSECOPS_TARGET_PORT:-6880}"
SEED_FILE="${DAST_SEED_FILE:-$CI_DIR/config/dast-seed-urls.txt}"
scan_status=0
scan_count=0
: > "$EVIDENCE_DIR/zap-console.txt"

if [ ! -s "$SEED_FILE" ]; then
  record_status dast FAILED "DAST seed file is missing or empty: $SEED_FILE"
  exit 1
fi

while IFS= read -r seed_path || [ -n "$seed_path" ]; do
  seed_path="${seed_path%%#*}"
  seed_path="$(printf '%s' "$seed_path" | xargs)"
  if [ -z "$seed_path" ]; then
    continue
  fi
  if [[ "$seed_path" != /* ]]; then
    seed_path="/$seed_path"
  fi

  scan_count=$((scan_count + 1))
  safe_name=$(printf '%s' "$seed_path" | sed 's#^/##; s#[^A-Za-z0-9._-]#-#g; s#^$#root#')
  target_url="http://${TARGET_HOST}:${TARGET_PORT}${seed_path}"

  {
    echo "--- ZAP baseline seed: $target_url ---"
  } >> "$EVIDENCE_DIR/zap-console.txt"

  set +e
  docker run --rm \
    --network "$DEMO_NETWORK" \
    -v "$EVIDENCE_DIR:/zap/wrk/:rw" \
    "$ZAP_IMAGE" \
    zap-baseline.py \
    -t "$target_url" \
    -m 2 \
    -I \
    -r "zap-report-${safe_name}.html" \
    -J "zap-report-${safe_name}.json" \
    -w "zap-report-${safe_name}.md" \
    >> "$EVIDENCE_DIR/zap-console.txt" 2>&1
  zap_status=$?
  set -e

  if [ "$zap_status" -ne 0 ]; then
    echo "ZAP returned exit code $zap_status for $target_url; passive findings are reported but not enforced." >> "$EVIDENCE_DIR/zap-console.txt"
    if [ "$zap_status" -gt 2 ]; then
      scan_status=1
    fi
  fi
  if [ ! -s "$EVIDENCE_DIR/zap-report-${safe_name}.html" ] || [ ! -s "$EVIDENCE_DIR/zap-report-${safe_name}.json" ]; then
    scan_status=1
  fi
done < "$SEED_FILE"

if [ "$scan_count" -eq 0 ]; then
  record_status dast FAILED "DAST seed file did not contain any active seed paths."
  exit 1
fi

export EVIDENCE_DIR TARGET_HOST TARGET_PORT scan_count
python3 - <<'PY'
import json
import os
from pathlib import Path

evidence = Path(os.environ["EVIDENCE_DIR"])
summary = {
    "target": f"http://{os.environ.get('TARGET_HOST', 'pmhub-gateway')}:{os.environ.get('TARGET_PORT', '6880')}",
    "scanMode": "ZAP Baseline passive scan",
    "seedCount": int(os.environ.get("scan_count", "0")),
    "reports": [],
}
for report in sorted(evidence.glob("zap-report-*.json")):
    item = {"report": report.name, "alerts": None}
    try:
        data = json.loads(report.read_text(encoding="utf-8"))
        site = data.get("site", [])
        alerts = []
        for entry in site:
            alerts.extend(entry.get("alerts", []))
        item["alerts"] = len(alerts)
        item["highAlerts"] = sum(1 for alert in alerts if str(alert.get("riskcode")) == "3")
        item["mediumAlerts"] = sum(1 for alert in alerts if str(alert.get("riskcode")) == "2")
        item["lowAlerts"] = sum(1 for alert in alerts if str(alert.get("riskcode")) == "1")
    except Exception as exc:
        item["error"] = str(exc)
    summary["reports"].append(item)
(evidence / "zap-summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
print(json.dumps(summary, indent=2))
PY

if [ "$scan_status" -ne 0 ]; then
  record_status dast FAILED "ZAP Baseline failed to produce valid reports for one or more Gateway seed paths."
  exit 1
fi

record_status dast PASS "ZAP Baseline completed against $scan_count Gateway seed paths without enforcing passive findings."
