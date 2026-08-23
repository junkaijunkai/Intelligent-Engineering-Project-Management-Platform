#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CI_DIR="$ROOT_DIR/ci"
OUT_DIR="$ROOT_DIR/devsecops-demo/out"
TMP_DIR="$ROOT_DIR/devsecops-demo/tmp"

# shellcheck disable=SC1091
source "$CI_DIR/config/tool-versions.env"

DEMO_NETWORK="${DEVSECOPS_NETWORK:-pvision-devsecops-demo-net}"
REDIS_CONTAINER="pvision-devsecops-demo-redis"
GATEWAY_CONTAINER="pvision-devsecops-demo-gateway"
GATEWAY_IMAGE="pvision-devsecops-demo-gateway:demo"

mkdir -p "$OUT_DIR" "$TMP_DIR"

log() {
  printf '[devsecops-demo] %s\n' "$*"
}

record_status() {
  local stage="$1"
  local status="$2"
  local detail="$3"
  mkdir -p "$OUT_DIR/00-metadata/status"
  STAGE="$stage" STATUS="$status" DETAIL="$detail" python3 - <<'PY'
import json, os
from pathlib import Path
root = Path(os.environ["OUT_DIR"]) if "OUT_DIR" in os.environ else None
if root is None:
    raise SystemExit("OUT_DIR missing")
path = root / "00-metadata" / "status" / f"{os.environ['STAGE']}.json"
path.write_text(json.dumps({
    "stage": os.environ["STAGE"],
    "status": os.environ["STATUS"],
    "detail": os.environ["DETAIL"],
}, indent=2) + "\n", encoding="utf-8")
PY
}

export ROOT_DIR CI_DIR OUT_DIR TMP_DIR
export DEMO_NETWORK REDIS_CONTAINER GATEWAY_CONTAINER GATEWAY_IMAGE
