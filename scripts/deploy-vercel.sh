#!/usr/bin/env bash
# Deploy web to Vercel. Requires: vercel CLI, authenticated session.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/web"

if ! command -v vercel >/dev/null 2>&1; then
  echo "Install Vercel CLI: npm i -g vercel"
  exit 1
fi

npm ci || npm install
npm run build
vercel --prod
echo "Done. Set VITE_* env vars in Vercel dashboard — see DEPLOY.md"
