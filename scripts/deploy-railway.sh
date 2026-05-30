#!/usr/bin/env bash
# Deploy brain to Railway. Requires: railway CLI, authenticated session.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/brain"

if ! command -v railway >/dev/null 2>&1; then
  echo "Install Railway CLI: npm i -g @railway/cli"
  exit 1
fi

echo "Deploying brain to Railway..."
railway up --detach
echo "Done. Set env vars in Railway dashboard — see DEPLOY.md"
