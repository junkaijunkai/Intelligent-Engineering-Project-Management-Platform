#!/usr/bin/env bash
set -uo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

EVIDENCE_DIR="$OUT_DIR/01-testing/unit"
mkdir -p "$EVIDENCE_DIR/junit" "$EVIDENCE_DIR/jacoco"
LOG_FILE="$EVIDENCE_DIR/maven-test.log"

set +e
mvn -f "$ROOT_DIR/pom.xml" test -B -Dspring.profiles.active=test > "$LOG_FILE" 2>&1
maven_status=$?
set -e

while IFS= read -r file; do
  module=$(python3 -c 'import os,sys; print(os.path.relpath(os.path.dirname(sys.argv[1]), sys.argv[2]).replace("/target/surefire-reports", "").replace("/", "__"))' "$file" "$ROOT_DIR")
  cp "$file" "$EVIDENCE_DIR/junit/${module}__$(basename "$file")"
done < <(find "$ROOT_DIR" -path "$ROOT_DIR/pmhub-boot" -prune -o -path '*/target/surefire-reports/TEST-*.xml' -type f -print)

while IFS= read -r file; do
  module=$(python3 -c 'import os,sys; print(os.path.relpath(os.path.dirname(sys.argv[1]), sys.argv[2]).replace("/target/site/jacoco", "").replace("/", "__"))' "$file" "$ROOT_DIR")
  mkdir -p "$EVIDENCE_DIR/jacoco/$module"
  cp -R "$(dirname "$file")/." "$EVIDENCE_DIR/jacoco/$module/"
done < <(find "$ROOT_DIR" -path "$ROOT_DIR/pmhub-boot" -prune -o -path '*/target/site/jacoco/jacoco.xml' -type f -print)

MAVEN_STATUS="$maven_status" python3 - <<'PY'
import json, os, xml.etree.ElementTree as ET
from pathlib import Path
out = Path(os.environ["OUT_DIR"]) / "01-testing/unit"
tests = failures = errors = skipped = 0
for path in (out / "junit").glob("*.xml"):
    root = ET.parse(path).getroot()
    tests += int(root.attrib.get("tests", 0))
    failures += int(root.attrib.get("failures", 0))
    errors += int(root.attrib.get("errors", 0))
    skipped += int(root.attrib.get("skipped", 0))

covered = missed = 0
for path in (out / "jacoco").glob("*/jacoco.xml"):
    root = ET.parse(path).getroot()
    for counter in root.findall("counter"):
        if counter.attrib.get("type") == "LINE":
            covered += int(counter.attrib.get("covered", 0))
            missed += int(counter.attrib.get("missed", 0))
coverage = round(100 * covered / (covered + missed), 2) if covered + missed else 0
summary = {
    "status": "PASS" if int(os.environ["MAVEN_STATUS"]) == 0 and failures + errors == 0 else "FAIL",
    "tests": tests,
    "failures": failures,
    "errors": errors,
    "skipped": skipped,
    "lineCoveragePercent": coverage,
    "coverageGateEnabled": False,
}
(out / "unit-test-summary.json").write_text(json.dumps(summary, indent=2) + "\n")
PY

if [ "$maven_status" -ne 0 ]; then
  record_status unit-tests FAILED "Maven tests failed; available reports were retained."
  exit "$maven_status"
fi
test -s "$EVIDENCE_DIR/unit-test-summary.json"
record_status unit-tests PASS "Maven tests passed and JUnit/JaCoCo evidence was collected."
