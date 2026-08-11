#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

EVIDENCE_DIR="$OUT_DIR/07-cd"
mkdir -p "$EVIDENCE_DIR"

image="${GHCR_IMAGE:-}"
sha_tag="${GHCR_SHA_TAG:-}"
latest_tag="${GHCR_LATEST_TAG:-demo-latest}"
digest="${GHCR_DIGEST:-}"
login_outcome="${GHCR_LOGIN_OUTCOME:-unknown}"
build_outcome="${GHCR_BUILD_OUTCOME:-unknown}"
container="pvision-devsecops-cd-staging"
staging_url="http://127.0.0.1:18081/health"

status="FAILED"
detail="GHCR image metadata was missing; deployment was not attempted."
container_id=""
health_status="000"

{
  printf 'Registry: ghcr.io\n'
  printf 'Image: %s\n' "${image:-not available}"
  printf 'SHA tag: %s\n' "${sha_tag:-not available}"
  printf 'Latest tag: %s\n' "$latest_tag"
  printf 'Digest: %s\n' "${digest:-not available}"
  printf 'GHCR login outcome: %s\n' "$login_outcome"
  printf 'Build and push outcome: %s\n' "$build_outcome"
  printf 'Source commit: %s\n' "${GITHUB_SHA:-not available}"
  printf 'Repository: %s\n' "${GITHUB_REPOSITORY:-not available}"
} > "$EVIDENCE_DIR/ghcr-push.txt"

if [ -n "$image" ] && [ -n "$sha_tag" ]; then
  full_image="$image:$sha_tag"
  set +e
  docker pull "$full_image" > "$EVIDENCE_DIR/ghcr-pull.txt" 2>&1
  pull_status=$?
  docker rm -f "$container" >/dev/null 2>&1 || true
  if [ "$pull_status" -eq 0 ]; then
    container_id=$(docker run -d --name "$container" -p 18081:80 "$full_image" 2>>"$EVIDENCE_DIR/deployment-console.txt")
    run_status=$?
    if [ "$run_status" -eq 0 ]; then
      for _ in $(seq 1 30); do
        health_status=$(curl --silent --show-error \
          --dump-header "$EVIDENCE_DIR/deployment-health-headers.txt" \
          --output "$EVIDENCE_DIR/deployment-health.json" \
          --write-out '%{http_code}' \
          "$staging_url" 2>>"$EVIDENCE_DIR/deployment-console.txt" || true)
        if [ "$health_status" = "200" ]; then
          status="PASS"
          detail="GHCR image was pulled and deployed to an ephemeral GitHub Actions staging container."
          break
        fi
        sleep 1
      done
    else
      detail="GHCR image was pulled, but the staging container failed to start."
    fi
  else
    detail="The pushed GHCR image could not be pulled for deployment verification."
  fi
  set -e
else
  full_image="not available"
fi

docker container inspect "$container" > "$EVIDENCE_DIR/deployment-container-inspect.json" 2>/dev/null || printf '[]\n' > "$EVIDENCE_DIR/deployment-container-inspect.json"
docker logs "$container" > "$EVIDENCE_DIR/deployment-container-logs.txt" 2>&1 || printf 'Container logs are not available.\n' > "$EVIDENCE_DIR/deployment-container-logs.txt"

if [ ! -s "$EVIDENCE_DIR/deployment-health-headers.txt" ]; then
  printf 'HTTP health headers are not available.\n' > "$EVIDENCE_DIR/deployment-health-headers.txt"
fi
if [ ! -s "$EVIDENCE_DIR/deployment-health.json" ]; then
  printf '{"status":"FAILED","detail":"Health response was not available."}\n' > "$EVIDENCE_DIR/deployment-health.json"
fi
if [ ! -s "$EVIDENCE_DIR/deployment-console.txt" ]; then
  printf 'No deployment console errors were recorded.\n' > "$EVIDENCE_DIR/deployment-console.txt"
fi
if [ ! -s "$EVIDENCE_DIR/ghcr-pull.txt" ]; then
  printf 'GHCR pull was not attempted.\n' > "$EVIDENCE_DIR/ghcr-pull.txt"
fi

CD_STATUS="$status" \
CD_DETAIL="$detail" \
CD_IMAGE="$image" \
CD_SHA_TAG="$sha_tag" \
CD_LATEST_TAG="$latest_tag" \
CD_DIGEST="$digest" \
CD_LOGIN_OUTCOME="$login_outcome" \
CD_BUILD_OUTCOME="$build_outcome" \
CD_FULL_IMAGE="$full_image" \
CD_CONTAINER="$container" \
CD_CONTAINER_ID="$container_id" \
CD_HEALTH_STATUS="$health_status" \
CD_STAGING_URL="$staging_url" \
python3 - <<'PY'
import json, os
from pathlib import Path

out = Path(os.environ["OUT_DIR"]) / "07-cd"
image = {
    "registry": "ghcr.io",
    "image": os.environ["CD_IMAGE"],
    "tags": [x for x in [os.environ["CD_SHA_TAG"], os.environ["CD_LATEST_TAG"]] if x],
    "digest": os.environ["CD_DIGEST"],
    "loginOutcome": os.environ["CD_LOGIN_OUTCOME"],
    "buildPushOutcome": os.environ["CD_BUILD_OUTCOME"],
    "sourceCommit": os.environ.get("GITHUB_SHA", ""),
    "repository": os.environ.get("GITHUB_REPOSITORY", ""),
    "packageUrl": f"https://github.com/{os.environ.get('GITHUB_REPOSITORY', '')}/pkgs/container/pvision-devsecops-demo-frontend",
}
deployment = {
    "status": os.environ["CD_STATUS"],
    "detail": os.environ["CD_DETAIL"],
    "environment": "GitHub Actions ephemeral staging",
    "image": os.environ["CD_FULL_IMAGE"],
    "containerName": os.environ["CD_CONTAINER"],
    "containerId": os.environ["CD_CONTAINER_ID"],
    "healthUrl": os.environ["CD_STAGING_URL"],
    "healthHttpStatus": os.environ["CD_HEALTH_STATUS"],
    "evidence": {
        "pushLog": "07-cd/ghcr-push.txt",
        "pullLog": "07-cd/ghcr-pull.txt",
        "healthResponse": "07-cd/deployment-health.json",
        "containerInspect": "07-cd/deployment-container-inspect.json",
        "containerLogs": "07-cd/deployment-container-logs.txt",
    },
}
(out / "ghcr-image.json").write_text(json.dumps(image, indent=2) + "\n", encoding="utf-8")
(out / "deployment-summary.json").write_text(json.dumps(deployment, indent=2) + "\n", encoding="utf-8")
PY

if [ "$status" = "PASS" ]; then
  record_status cd-deploy PASS "$detail"
else
  record_status cd-deploy FAILED "$detail"
fi

exit 0
