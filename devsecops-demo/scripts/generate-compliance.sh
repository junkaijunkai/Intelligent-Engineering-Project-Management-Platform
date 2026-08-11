#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

GIT_DIR="$OUT_DIR/04-compliance/git"
GDPR_DIR="$OUT_DIR/04-compliance/gdpr"
VULN_DIR="$OUT_DIR/05-vulnerability"
mkdir -p "$GIT_DIR" "$GDPR_DIR" "$VULN_DIR"

git -C "$ROOT_DIR" log --date=iso-strict --pretty=format:'%h | %ad | %an | %s' -30 > "$GIT_DIR/git-audit-trail.txt"
git -C "$ROOT_DIR" log --date=short --pretty=format:'%h | %ad | %s' --grep='security\|OWASP\|JWT\|SnakeYAML\|SAST\|Sonar' -i > "$VULN_DIR/remediation-history.txt" || true

python3 "$DEMO_DIR/scripts/generate_evidence.py" compliance
record_status compliance PASS "Git audit trail, historical remediation, GDPR mapping, and rescan evidence were generated."
