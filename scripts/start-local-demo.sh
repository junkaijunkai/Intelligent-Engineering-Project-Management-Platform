#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repository_root}"

export HOST="${HOST:-127.0.0.1}"
export PORT="${PORT:-4173}"

exec node demo/mock-server.mjs
