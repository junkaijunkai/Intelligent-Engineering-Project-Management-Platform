#!/usr/bin/env bash
set -uo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

UNIT_TEST_MODULE="${UNIT_TEST_MODULE:-}"
UNIT_TEST_SERVICE="${UNIT_TEST_SERVICE:-${UNIT_TEST_MODULE//\//__}}"
ENFORCE_QUALITY_GATE="${ENFORCE_QUALITY_GATE:-true}"

if [ -z "$UNIT_TEST_MODULE" ]; then
  log "UNIT_TEST_MODULE is required."
  record_status unit-tests FAILED "UNIT_TEST_MODULE is required."
  exit 1
fi

MODULE_DIR="$ROOT_DIR/$UNIT_TEST_MODULE"
if [ ! -d "$MODULE_DIR" ]; then
  log "Unit-test module does not exist: $UNIT_TEST_MODULE"
  record_status "unit-tests-$UNIT_TEST_SERVICE" FAILED "Unit-test module does not exist: $UNIT_TEST_MODULE"
  exit 1
fi

EVIDENCE_DIR="$OUT_DIR/01-testing/unit/$UNIT_TEST_SERVICE"
# Do not allow reports from a previous run to satisfy this run's gate.
rm -rf "$EVIDENCE_DIR/junit" "$EVIDENCE_DIR/jacoco"
mkdir -p "$EVIDENCE_DIR/junit" "$EVIDENCE_DIR/jacoco"
LOG_FILE="$EVIDENCE_DIR/maven-test.log"

set +e
# The repository targets Java 8.  With the current Surefire/JaCoCo
# configuration, forked test JVMs can lose the reactor module classes;
# in-process execution preserves the compiled test classpath and coverage.
mvn -f "$ROOT_DIR/pom.xml" -pl "$UNIT_TEST_MODULE" -am clean test -B -Dspring.profiles.active=test -DforkCount=0 > "$LOG_FILE" 2>&1
maven_status=$?
set -e

while IFS= read -r file; do
  module=$(python3 -c 'import os,sys; print(os.path.relpath(os.path.dirname(sys.argv[1]), sys.argv[2]).replace("/target/surefire-reports", "").replace("/", "__"))' "$file" "$ROOT_DIR")
  cp "$file" "$EVIDENCE_DIR/junit/${module}__$(basename "$file")"
done < <(find "$MODULE_DIR" -path '*/target/surefire-reports/TEST-*.xml' -type f -print)

while IFS= read -r file; do
  module=$(python3 -c 'import os,sys; print(os.path.relpath(os.path.dirname(sys.argv[1]), sys.argv[2]).replace("/target/site/jacoco", "").replace("/", "__"))' "$file" "$ROOT_DIR")
  mkdir -p "$EVIDENCE_DIR/jacoco/$module"
  cp -R "$(dirname "$file")/." "$EVIDENCE_DIR/jacoco/$module/"
done < <(find "$MODULE_DIR" -path '*/target/site/jacoco/jacoco.xml' -type f -print)

MAVEN_STATUS="$maven_status" ROOT_DIR="$ROOT_DIR" UNIT_TEST_MODULE="$UNIT_TEST_MODULE" UNIT_TEST_SERVICE="$UNIT_TEST_SERVICE" python3 - <<'PY'
import json, os, xml.etree.ElementTree as ET
from pathlib import Path
service = os.environ["UNIT_TEST_SERVICE"]
module = os.environ["UNIT_TEST_MODULE"]
out = Path(os.environ["OUT_DIR"]) / "01-testing/unit" / service
root_dir = Path(os.environ["ROOT_DIR"])
minimum = float(os.environ.get("MINIMUM_LINE_COVERAGE_PERCENT", "70.0"))
tests = failures = errors = skipped = 0
for path in (out / "junit").glob("*.xml"):
    root = ET.parse(path).getroot()
    tests += int(root.attrib.get("tests", 0))
    failures += int(root.attrib.get("failures", 0))
    errors += int(root.attrib.get("errors", 0))
    skipped += int(root.attrib.get("skipped", 0))

module_results = []
covered = missed = 0
module_dir = root_dir / module
evidence_name = module.replace("/", "__")
report_path = module_dir / "target/site/jacoco/jacoco.xml"
result = {"module": module, "service": service, "report": evidence_name, "status": "FAIL"}
if not report_path.is_file() or report_path.stat().st_size == 0:
    result["reason"] = "missing JaCoCo report"
else:
    try:
        root = ET.parse(report_path).getroot()
        counter = next((item for item in root.findall("counter")
                        if item.attrib.get("type") == "LINE"), None)
    except (ET.ParseError, OSError) as exc:
        result["reason"] = f"invalid JaCoCo report: {exc}"
    else:
        if counter is None:
            result["reason"] = "missing LINE execution data"
        else:
            module_covered = int(counter.attrib.get("covered", 0))
            module_missed = int(counter.attrib.get("missed", 0))
            total = module_covered + module_missed
            module_coverage = round(100 * module_covered / total, 2) if total else 0.0
            covered += module_covered
            missed += module_missed
            result.update({"coveredLines": module_covered, "missedLines": module_missed,
                           "lineCoveragePercent": module_coverage})
            if total == 0:
                result["reason"] = "LINE counter has no execution data"
            elif module_coverage < minimum:
                result["reason"] = f"below minimum {minimum:.2f}%"
            else:
                result["status"] = "PASS"
module_results.append(result)

coverage = round(100 * covered / (covered + missed), 2) if covered + missed else 0.0
module_failures = [item for item in module_results if item["status"] != "PASS"]
gate_passed = not module_failures and bool(module_results)
summary = {
    "status": "PASS" if int(os.environ["MAVEN_STATUS"]) == 0 and failures + errors == 0 and gate_passed else "FAIL",
    "tests": tests,
    "failures": failures,
    "errors": errors,
    "skipped": skipped,
    "lineCoveragePercent": coverage,
    "minimumLineCoveragePercent": minimum,
    "coverageGateEnabled": True,
    "modules": module_results,
    "coverageFailures": module_failures,
}
(out / "unit-test-summary.json").write_text(json.dumps(summary, indent=2) + "\n")
print("PASS" if summary["status"] == "PASS" else "FAIL")
PY

if [ "$maven_status" -ne 0 ]; then
  record_status "unit-tests-$UNIT_TEST_SERVICE" FAILED "Maven tests failed for $UNIT_TEST_MODULE; available reports were retained."
  if [ "$ENFORCE_QUALITY_GATE" = "true" ]; then
    exit "$maven_status"
  fi
  exit 0
fi
if ! test -s "$EVIDENCE_DIR/unit-test-summary.json"; then
  record_status "unit-tests-$UNIT_TEST_SERVICE" FAILED "Unit-test summary was not generated for $UNIT_TEST_MODULE."
  if [ "$ENFORCE_QUALITY_GATE" = "true" ]; then
    exit 1
  fi
  exit 0
fi
gate_status=$(MAVEN_STATUS=0 ROOT_DIR="$ROOT_DIR" OUT_DIR="$OUT_DIR" UNIT_TEST_SERVICE="$UNIT_TEST_SERVICE" python3 -c 'import json, os; print(json.load(open(os.path.join(os.environ["OUT_DIR"], "01-testing/unit", os.environ["UNIT_TEST_SERVICE"], "unit-test-summary.json")))["status"])')
if [ "$gate_status" != "PASS" ]; then
  record_status "unit-tests-$UNIT_TEST_SERVICE" FAILED "$UNIT_TEST_MODULE is missing JaCoCo execution data or is below the 70% line-coverage gate."
  if [ "$ENFORCE_QUALITY_GATE" = "true" ]; then
    exit 1
  fi
  exit 0
fi
record_status "unit-tests-$UNIT_TEST_SERVICE" PASS "$UNIT_TEST_MODULE Maven tests passed and met the 70% JaCoCo line-coverage gate."
