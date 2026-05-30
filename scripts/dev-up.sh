#!/usr/bin/env bash
# Start the full Penlo stack locally (Postgres + Brain + optional web).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Generating dev secrets..."
bash "$ROOT/scripts/generate-env.sh"

echo "==> Starting Docker runtime..."
if ! docker info >/dev/null 2>&1; then
  if command -v colima >/dev/null 2>&1; then
    # Start Colima with 60GB VM disk so Docker images and volumes don't fill host space.
    # If it's already running, this is a no-op.
    colima start --disk 60 --memory 4 --cpu 4 2>/dev/null || colima start 2>/dev/null || true
  fi
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker is not running. Install Docker Desktop or run: brew install colima && colima start"
  exit 1
fi

# Use Colima Docker socket and avoid docker-credential-desktop errors
export DOCKER_HOST="${DOCKER_HOST:-unix://${HOME}/.colima/default/docker.sock}"
export DOCKER_CONFIG="${DOCKER_CONFIG:-/tmp/penlo-docker-config}"
mkdir -p "$DOCKER_CONFIG"
echo '{"auths":{}}' > "$DOCKER_CONFIG/config.json"

COMPOSE="docker-compose"

echo "==> Starting brain stack (postgres + backend)..."
cd "$ROOT/brain"
$COMPOSE -f docker-compose.yml -f docker-compose.dev.yml up -d postgres
echo "Waiting for Postgres..."
for i in $(seq 1 30); do
  if $COMPOSE exec -T postgres pg_isready -U penlo -d penlo_enterprise >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

$COMPOSE -f docker-compose.yml -f docker-compose.dev.yml up -d backend

echo "==> Brain API: http://localhost:8000/health"
echo "==> To start web dashboard:"
echo "    cd web && npm run dev"
echo "==> To create admin user:"
echo "    cd brain/backend && source .venv/bin/activate && python scripts/create_admin.py"
