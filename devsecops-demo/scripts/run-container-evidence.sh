#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

EVIDENCE_DIR="$OUT_DIR/02-container"
mkdir -p "$EVIDENCE_DIR"

docker network inspect "$DEMO_NETWORK" >/dev/null 2>&1 || docker network create "$DEMO_NETWORK" >/dev/null
docker rm -f "$FRONTEND_CONTAINER" >/dev/null 2>&1 || true

log "Building frontend demo image"
docker build \
  --build-arg "NGINX_IMAGE=$NGINX_IMAGE" \
  -f "$DEMO_DIR/container/frontend/Dockerfile" \
  -t "$FRONTEND_IMAGE" \
  "$ROOT_DIR"

docker run -d \
  --name "$FRONTEND_CONTAINER" \
  --network "$DEMO_NETWORK" \
  -p 18080:80 \
  "$FRONTEND_IMAGE" >/dev/null

healthy=false
for _ in $(seq 1 30); do
  if curl --silent --fail http://127.0.0.1:18080/health >/dev/null; then
    healthy=true
    break
  fi
  sleep 1
done

docker image inspect "$FRONTEND_IMAGE" > "$EVIDENCE_DIR/frontend-image-inspect.json"
docker container inspect "$FRONTEND_CONTAINER" > "$EVIDENCE_DIR/frontend-container-inspect.json"
docker ps --filter "name=$FRONTEND_CONTAINER" --no-trunc > "$EVIDENCE_DIR/frontend-docker-ps.txt"
docker logs "$FRONTEND_CONTAINER" > "$EVIDENCE_DIR/frontend-logs.txt" 2>&1

if [ "$healthy" != true ]; then
  record_status frontend FAILED "Frontend demo container did not become healthy."
  exit 1
fi

curl --silent --show-error --fail http://127.0.0.1:18080/health > "$EVIDENCE_DIR/frontend-health.json"
record_status frontend PASS "Frontend demo image built and container health endpoint returned HTTP 200."
