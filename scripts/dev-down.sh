#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/brain"
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down
echo "Penlo stack stopped."
