#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

ENFORCE_QUALITY_GATE="${ENFORCE_QUALITY_GATE:-true}"
UNIT_DIR="$OUT_DIR/01-testing/unit"

export ENFORCE_QUALITY_GATE
mkdir -p "$UNIT_DIR"

python3 - <<'PY'
import json
import os
from pathlib import Path

unit_dir = Path(os.environ["OUT_DIR"]) / "01-testing/unit"
summary_paths = sorted(
    path for path in unit_dir.glob("*/unit-test-summary.json")
    if path.parent != unit_dir
)

tests = failures = errors = skipped = 0
covered = missed = 0
modules = []
coverage_failures = []
summary_failures = []

for path in summary_paths:
    summary = json.loads(path.read_text(encoding="utf-8"))
    if summary.get("status") != "PASS":
        summary_failures.append({
            "summary": str(path.relative_to(unit_dir)),
            "status": summary.get("status", "UNKNOWN"),
        })
    tests += int(summary.get("tests", 0))
    failures += int(summary.get("failures", 0))
    errors += int(summary.get("errors", 0))
    skipped += int(summary.get("skipped", 0))
    for module in summary.get("modules", []):
        modules.append(module)
        covered += int(module.get("coveredLines", 0))
        missed += int(module.get("missedLines", 0))
        if module.get("status") != "PASS":
            coverage_failures.append(module)

coverage = round(100 * covered / (covered + missed), 2) if covered + missed else 0.0
status = "PASS" if summary_paths and failures + errors == 0 and not coverage_failures and not summary_failures else "FAIL"
minimums = [
    float(json.loads(path.read_text(encoding="utf-8")).get("minimumLineCoveragePercent", 70.0))
    for path in summary_paths
]

aggregate = {
    "status": status,
    "tests": tests,
    "failures": failures,
    "errors": errors,
    "skipped": skipped,
    "lineCoveragePercent": coverage,
    "minimumLineCoveragePercent": max(minimums) if minimums else 70.0,
    "coverageGateEnabled": True,
    "qualityGateEnforced": os.environ.get("ENFORCE_QUALITY_GATE", "true") == "true",
    "modules": modules,
    "coverageFailures": coverage_failures,
    "summaryFailures": summary_failures,
}

if not summary_paths:
    aggregate["reason"] = "No module unit-test summaries were found."

(unit_dir / "unit-test-summary.json").write_text(
    json.dumps(aggregate, indent=2) + "\n",
    encoding="utf-8",
)
print(json.dumps(aggregate, indent=2))
PY

gate_status=$(python3 -c 'import json, os; print(json.load(open(os.path.join(os.environ["OUT_DIR"], "01-testing/unit/unit-test-summary.json")))["status"])')
if [ "$gate_status" != "PASS" ]; then
  record_status coverage-gate FAILED "One or more service test or coverage checks failed."
  if [ "$ENFORCE_QUALITY_GATE" = "true" ]; then
    exit 1
  fi
  log "Coverage gate failed, but ENFORCE_QUALITY_GATE=false; continuing."
  exit 0
fi

record_status coverage-gate PASS "All service test and coverage checks passed."
