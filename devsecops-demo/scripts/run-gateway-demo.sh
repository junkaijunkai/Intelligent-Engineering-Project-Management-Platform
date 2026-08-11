#!/usr/bin/env bash
set -uo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

EVIDENCE_DIR="$OUT_DIR/02-container/gateway"
IMAGE_DIR="$OUT_DIR/03-security/image"
CONTEXT_DIR="$TMP_DIR/gateway-context"
mkdir -p "$EVIDENCE_DIR" "$IMAGE_DIR" "$CONTEXT_DIR"

gateway_result=FAILED
detail="Gateway evidence was attempted but did not become ready within the time box."

set +e
timeout_cmd=()
if command -v timeout >/dev/null 2>&1; then
  timeout_cmd=(timeout 300)
elif command -v gtimeout >/dev/null 2>&1; then
  timeout_cmd=(gtimeout 300)
fi

"${timeout_cmd[@]}" mvn -f "$ROOT_DIR/pom.xml" package -pl pmhub-gateway -am -B -DskipTests -Ddependency-check.skip=true \
  > "$EVIDENCE_DIR/gateway-build.log" 2>&1
build_status=$?

if [ "$build_status" -eq 0 ]; then
  jar_file=$(find "$ROOT_DIR/pmhub-gateway/target" -maxdepth 1 -name '*.jar' ! -name '*-sources.jar' ! -name '*-javadoc.jar' | head -1)
  if [ -n "${jar_file:-}" ]; then
    cp "$jar_file" "$CONTEXT_DIR/app.jar"
    cp "$DEMO_DIR/container/gateway/Dockerfile" "$CONTEXT_DIR/Dockerfile"
    docker build --build-arg "JAVA_RUNTIME_IMAGE=$JAVA_RUNTIME_IMAGE" -t "$GATEWAY_IMAGE" "$CONTEXT_DIR" \
      > "$EVIDENCE_DIR/gateway-image-build.log" 2>&1
    image_status=$?
    if [ "$image_status" -eq 0 ]; then
      docker rm -f "$GATEWAY_CONTAINER" "$REDIS_CONTAINER" >/dev/null 2>&1
      docker run -d --name "$REDIS_CONTAINER" --network "$DEMO_NETWORK" "$REDIS_IMAGE" >/dev/null
      docker run -d \
        --name "$GATEWAY_CONTAINER" \
        --network "$DEMO_NETWORK" \
        -p 16880:6880 \
        -e SPRING_PROFILES_ACTIVE=test \
        -e SPRING_REDIS_HOST="$REDIS_CONTAINER" \
        -e SPRING_REDIS_PORT=6379 \
        -e TOKEN_SECRET=devsecops-demo-only-secret-value-32chars \
        -e TOKEN_HEADER=Authorization \
        -e SECURITY_IGNORE_WHITES_0=/actuator/health \
        "$GATEWAY_IMAGE" >/dev/null

      for _ in $(seq 1 60); do
        status=$(curl --silent --output "$EVIDENCE_DIR/gateway-health-response.json" --write-out '%{http_code}' http://127.0.0.1:16880/actuator/health || true)
        if [ "$status" = "200" ] || [ "$status" = "503" ]; then
          gateway_result=PASS
          detail="Gateway container started and returned an actuator health response."
          break
        fi
        sleep 2
      done
      docker image inspect "$GATEWAY_IMAGE" > "$EVIDENCE_DIR/gateway-image-inspect.json" 2>/dev/null
      docker container inspect "$GATEWAY_CONTAINER" > "$EVIDENCE_DIR/gateway-container-inspect.json" 2>/dev/null
      docker logs "$GATEWAY_CONTAINER" > "$EVIDENCE_DIR/gateway-logs.txt" 2>&1
    fi
  fi
fi
set -e

GATEWAY_STATUS="$gateway_result" GATEWAY_DETAIL="$detail" python3 - <<'PY'
import json, os
from pathlib import Path
path = Path(os.environ["OUT_DIR"]) / "02-container/gateway/gateway-status.json"
path.write_text(json.dumps({
    "status": os.environ["GATEWAY_STATUS"],
    "required": False,
    "detail": os.environ["GATEWAY_DETAIL"],
}, indent=2) + "\n")
PY

record_status gateway "$gateway_result" "$detail"
exit 0
