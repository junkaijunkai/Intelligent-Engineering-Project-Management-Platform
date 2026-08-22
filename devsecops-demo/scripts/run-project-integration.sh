#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

EVIDENCE_DIR="$OUT_DIR/01-testing/integration"
mkdir -p "$EVIDENCE_DIR"

services=(pmhub-nacos pmhub-mysql pmhub-redis pmhub-seata pmhub-gateway pmhub-auth pmhub-system pmhub-project pmhub-workflow pmhub-gen pmhub-job pmhub-monitor)

failures=0
for service in "${services[@]}"; do
  running=$(docker inspect --format '{{.State.Running}}' "$service" 2>/dev/null || printf 'false')
  if [ "$running" = "true" ]; then
    printf 'PASS %s running\n' "$service" >> "$EVIDENCE_DIR/service-health.txt"
  else
    printf 'FAIL %s not running\n' "$service" >> "$EVIDENCE_DIR/service-health.txt"
    failures=$((failures + 1))
  fi
done

gateway_status=$(curl --silent --show-error --output "$EVIDENCE_DIR/gateway-health.json" --write-out '%{http_code}' http://127.0.0.1:6880/actuator/health || true)
if [ "$gateway_status" != "200" ]; then
  failures=$((failures + 1))
fi

python3 - "$EVIDENCE_DIR/project-integration-summary.json" "$failures" "$gateway_status" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1])
failures = int(sys.argv[2])
path.write_text(json.dumps({
    "scope": "Full backend microservice Compose environment",
    "entrypoint": "Gateway",
    "servicesChecked": 12,
    "gatewayHttpStatus": int(sys.argv[3]) if sys.argv[3].isdigit() else 0,
    "failures": failures,
    "status": "PASS" if failures == 0 else "FAIL",
}, indent=2) + "\n")
PY

if [ "$failures" -ne 0 ]; then
  record_status integration FAILED "$failures project runtime checks failed."
  exit 1
fi
record_status integration PASS "All backend services and the Gateway health endpoint passed."
