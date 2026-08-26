#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD must be set}"
PROJECT_NAME="${CI_COMPOSE_PROJECT_NAME:-pvision-ci}"
COMPOSE_BASE="$ROOT_DIR/docker/docker-compose.yml"
RUNTIME_TMP_DIR="${RUNNER_TEMP:-$TMP_DIR}/pvision-ci-compose"
COMPOSE_OVERRIDE="$RUNTIME_TMP_DIR/docker-compose.ci.yml"
NACOS_CONFIG="$RUNTIME_TMP_DIR/nacos-application.properties"
SEATA_CONFIG="$RUNTIME_TMP_DIR/seata-application.yml"
NACOS_SQL="$RUNTIME_TMP_DIR/pmhub_nacos-ci.sql"
EVIDENCE_DIR="$OUT_DIR/05-runtime"
mkdir -p "$RUNTIME_TMP_DIR" "$EVIDENCE_DIR/logs"

cleanup() {
  docker compose -p "$PROJECT_NAME" -f "$COMPOSE_BASE" -f "$COMPOSE_OVERRIDE" down -v --remove-orphans >/dev/null 2>&1 || true
  rm -f "$ROOT_DIR"/pmhub-gateway/app.jar "$ROOT_DIR"/pmhub-auth/app.jar \
    "$ROOT_DIR"/pmhub-modules/pmhub-system/app.jar "$ROOT_DIR"/pmhub-modules/pmhub-project/app.jar \
    "$ROOT_DIR"/pmhub-modules/pmhub-workflow/app.jar "$ROOT_DIR"/pmhub-modules/pmhub-gen/app.jar \
    "$ROOT_DIR"/pmhub-modules/pmhub-job/app.jar "$ROOT_DIR"/pmhub-monitor/app.jar
}
trap cleanup EXIT

{
  sed -e "s|^db.url.0=.*|db.url.0=jdbc:mysql://pmhub-mysql:3306/pmhub-nacos?characterEncoding=utf8\\&useUnicode=true\\&useSSL=false\\&serverTimezone=UTC|" \
      -e "s|^db.password=.*|db.password=${MYSQL_ROOT_PASSWORD}|" \
      "$ROOT_DIR/docker/nacos/conf/application.properties"
  printf '%s\n' \
    'spring.autoconfigure.exclude=org.springframework.boot.actuate.autoconfigure.metrics.SystemMetricsAutoConfiguration'
} > "$NACOS_CONFIG"
sed -e "s|jdbc:mysql://localhost:3306/|jdbc:mysql://pmhub-mysql:3306/|g" \
    -e "s|127.0.0.1:8848|pmhub-nacos:8848|g" \
    -e "s|password: 123456|password: ${MYSQL_ROOT_PASSWORD}|g" \
    "$ROOT_DIR/docker/seata/seata-application.yml" > "$SEATA_CONFIG"
sed -e "s#jdbc:mysql://127.0.0.1:3306/#jdbc:mysql://pmhub-mysql:3306/#g" \
    -e "s/host: localhost/host: pmhub-redis/g" \
    -e "s/host: 127.0.0.1/host: pmhub-redis/g" \
    -e "s#redis://localhost:6379#redis://pmhub-redis:6379#g" \
    -e "s|server-addr: 127.0.0.1:8848|server-addr: pmhub-nacos:8848|g" \
    -e "s/password: 123456/password: ${MYSQL_ROOT_PASSWORD}/g" \
    "$ROOT_DIR/sql/pmhub_nacos.sql" > "$NACOS_SQL"

cat > "$COMPOSE_OVERRIDE" <<EOF
services:
  pmhub-nacos:
    volumes:
      - ${NACOS_CONFIG}:/home/nacos/conf/application.properties:ro
  pmhub-seata:
    volumes:
      - ${SEATA_CONFIG}:/seata-server/resources/application.yml:ro
EOF

modules=(
  "pmhub-gateway:pmhub-gateway"
  "pmhub-auth:pmhub-auth"
  "pmhub-modules/pmhub-system:pmhub-system"
  "pmhub-modules/pmhub-project:pmhub-project"
  "pmhub-modules/pmhub-workflow:pmhub-workflow"
  "pmhub-modules/pmhub-gen:pmhub-gen"
  "pmhub-modules/pmhub-job:pmhub-job"
  "pmhub-monitor:pmhub-monitor"
)
for item in "${modules[@]}"; do
  module="${item%%:*}"
  jar_file=$(find "$ROOT_DIR/$module/target" -maxdepth 1 -type f -name '*.jar' ! -name '*-sources.jar' ! -name '*-javadoc.jar' | head -1)
  test -n "$jar_file"
  cp "$jar_file" "$ROOT_DIR/$module/app.jar"
done

compose=(docker compose -p "$PROJECT_NAME" -f "$COMPOSE_BASE" -f "$COMPOSE_OVERRIDE")
export CI_COMPOSE_FILE="$COMPOSE_BASE:$COMPOSE_OVERRIDE"
export COMPOSE_PROJECT_NAME="$PROJECT_NAME"

capture_runtime_evidence() {
  "${compose[@]}" ps > "$EVIDENCE_DIR/compose-ps.txt" 2>&1 || true
  for service in pmhub-nacos pmhub-mysql pmhub-redis pmhub-seata pmhub-gateway pmhub-auth pmhub-system pmhub-project pmhub-workflow pmhub-gen pmhub-job pmhub-monitor; do
    docker logs "$service" > "$EVIDENCE_DIR/logs/$service.log" 2>&1 || true
  done
  if [ -s "$EVIDENCE_DIR/logs/pmhub-nacos.log" ]; then
    printf '%s\n' '--- Nacos runtime log (failure path) ---'
    cat "$EVIDENCE_DIR/logs/pmhub-nacos.log"
    printf '%s\n' '--- End Nacos runtime log ---'
  fi
}

"${compose[@]}" up -d pmhub-mysql
mysql_ready=false
for i in {1..60}; do
  if MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -h 127.0.0.1 -P 33706 -u root -e 'SELECT 1' >/dev/null 2>&1; then
    mysql_ready=true
    break
  fi
  sleep 2
done
if [ "$mysql_ready" != true ]; then
  capture_runtime_evidence
  printf '{"status":"FAIL","reason":"MySQL readiness check timed out."}\n' > "$EVIDENCE_DIR/gateway-health.json"
  record_status project-runtime FAILED "MySQL did not become ready; runtime logs and status were retained."
  exit 1
fi

run_sql() {
  local sql_file="$1"
  if ! MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -h 127.0.0.1 -P 33706 -u root < "$sql_file"; then
    capture_runtime_evidence
    printf '{"status":"FAIL","reason":"SQL initialization failed: %s"}\n' "$(basename "$sql_file")" > "$EVIDENCE_DIR/gateway-health.json"
    record_status project-runtime FAILED "SQL initialization failed; runtime logs and status were retained."
    exit 1
  fi
}

run_sql "$ROOT_DIR/sql/pmhub-system.sql"
run_sql "$ROOT_DIR/sql/pmhub-project.sql"
run_sql "$ROOT_DIR/sql/pmhub-workflow.sql"
run_sql "$ROOT_DIR/sql/pmhub-gen.sql"
run_sql "$ROOT_DIR/sql/pmhub_seata.sql"
run_sql "$NACOS_SQL"

if ! "${compose[@]}" up -d --build; then
  capture_runtime_evidence
  printf '{"status":"FAIL","reason":"Compose startup failed before Gateway health check."}\n' > "$EVIDENCE_DIR/gateway-health.json"
  record_status project-runtime FAILED "Compose startup failed; runtime logs and status were retained."
  exit 1
fi
for i in {1..90}; do
  gateway_status=$(curl --silent --output /dev/null --write-out '%{http_code}' http://127.0.0.1:6880/actuator/health || true)
  if [ "$gateway_status" = "200" ]; then break; fi
  sleep 4
done

if ! curl --fail --silent --show-error http://127.0.0.1:6880/actuator/health > "$EVIDENCE_DIR/gateway-health.json"; then
  capture_runtime_evidence
  printf '{"status":"FAIL","reason":"Gateway health check failed after Compose startup."}\n' > "$EVIDENCE_DIR/gateway-health.json"
  record_status project-runtime FAILED "Gateway health check failed; runtime logs and status were retained."
  exit 1
fi
"${compose[@]}" ps > "$EVIDENCE_DIR/compose-ps.txt"
docker network inspect "${PROJECT_NAME}_default" > "$EVIDENCE_DIR/network-inspect.json"

if ! bash "$CI_DIR/scripts/run-project-integration.sh"; then
  runtime_status=1
else
  runtime_status=0
fi

DEVSECOPS_NETWORK="${PROJECT_NAME}_default" DEVSECOPS_TARGET_HOST=pmhub-gateway DEVSECOPS_TARGET_PORT=6880 \
  bash "$CI_DIR/scripts/run-load-test.sh" || runtime_status=1

if [ "${RUN_DAST:-false}" = "true" ]; then
  DEVSECOPS_NETWORK="${PROJECT_NAME}_default" DEVSECOPS_TARGET_HOST=pmhub-gateway DEVSECOPS_TARGET_PORT=6880 \
    bash "$CI_DIR/scripts/run-dast.sh" || runtime_status=1
fi

for service in pmhub-nacos pmhub-mysql pmhub-redis pmhub-seata pmhub-gateway pmhub-auth pmhub-system pmhub-project pmhub-workflow pmhub-gen pmhub-job pmhub-monitor; do
  docker logs "$service" > "$EVIDENCE_DIR/logs/$service.log" 2>&1 || true
done

if [ "$runtime_status" -eq 0 ]; then
  record_status project-runtime PASS "Full backend Compose runtime checks and evidence collection completed."
else
  record_status project-runtime FAILED "One or more full backend Compose runtime checks failed; evidence was retained."
fi
exit "$runtime_status"
