#!/usr/bin/env bash
set -u
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

docker rm -f "$GATEWAY_CONTAINER" "$REDIS_CONTAINER" >/dev/null 2>&1 || true
docker network rm "$DEMO_NETWORK" >/dev/null 2>&1 || true
log "Removed demo containers and network; demo images were retained."
