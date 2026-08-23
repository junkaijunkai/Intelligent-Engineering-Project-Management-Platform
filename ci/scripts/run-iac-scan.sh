#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

export DEPLOY_ENV="${DEPLOY_ENV:-ci}"
export COMPLIANCE_MODE="${COMPLIANCE_MODE:-$DEPLOY_ENV}"
if [[ "$COMPLIANCE_MODE" != "local" && "$COMPLIANCE_MODE" != "ci" ]]; then
  echo "Unsupported COMPLIANCE_MODE: $COMPLIANCE_MODE" >&2
  exit 1
fi

python3 "$CI_DIR/scripts/iac_compliance.py"
record_status compliance-iac PASS "IaC policy scan completed in $COMPLIANCE_MODE mode."
