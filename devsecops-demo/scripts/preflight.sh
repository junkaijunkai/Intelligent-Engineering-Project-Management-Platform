#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

mkdir -p \
  "$OUT_DIR/00-metadata" \
  "$OUT_DIR/01-testing/unit" \
  "$OUT_DIR/01-testing/integration" \
  "$OUT_DIR/01-testing/load" \
  "$OUT_DIR/02-container" \
  "$OUT_DIR/03-security/sast" \
  "$OUT_DIR/03-security/image" \
  "$OUT_DIR/03-security/dast" \
  "$OUT_DIR/04-compliance/iac" \
  "$OUT_DIR/04-compliance/git" \
  "$OUT_DIR/04-compliance/gdpr" \
  "$OUT_DIR/05-vulnerability" \
  "$OUT_DIR/06-presentation/raw-screenshots"

{
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Git SHA: $(git -C "$ROOT_DIR" rev-parse HEAD)"
  echo "Git branch: $(git -C "$ROOT_DIR" branch --show-current)"
  echo "OS: $(uname -srm)"
  echo "Docker: $(docker version --format '{{.Client.Version}}/{{.Server.Version}}')"
  echo "Maven: $(mvn -version | head -1)"
  echo "Java: $(java -version 2>&1 | head -1)"
} > "$OUT_DIR/00-metadata/environment.txt"

python3 - <<'PY'
import json, os
from pathlib import Path
versions = {}
for line in (Path(os.environ["DEMO_DIR"]) / "config" / "tool-versions.env").read_text().splitlines():
    if line and not line.startswith("#"):
        key, value = line.split("=", 1)
        versions[key] = value
(Path(os.environ["OUT_DIR"]) / "00-metadata" / "toolchain.json").write_text(
    json.dumps(versions, indent=2) + "\n", encoding="utf-8"
)
PY

git -C "$ROOT_DIR" status --short > "$OUT_DIR/00-metadata/git-status-before.txt"
record_status preflight PASS "Docker, Maven, Java, Git, and output directories are available."
