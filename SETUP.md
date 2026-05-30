# Penlo Local Development Setup

## Prerequisites

- **Docker** (Docker Desktop or `brew install colima docker docker-compose`)
- **Colima** (if not using Docker Desktop): `colima start`
- **Node.js 20+** (for web dashboard)
- **Python 3.11** (for brain backend without Docker)
- **Xcode 16+** (for Flow iOS app)

## Quick Start

```bash
# 1. Start brain backend + Postgres
bash scripts/dev-up.sh

# 2. Start web dashboard
cd web && npm install && npm run dev
# → http://localhost:5173

# 3. Create admin user (first time)
cd brain/backend
python3.11 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python scripts/create_admin.py

# 4. Open Flow iOS app
open flow/flow.xcodeproj
# Configure Settings → Enterprise Brain URL: http://localhost:8000/api/v1/ingest/penlo-brain
# Generate API key from web → Connect App page
```

## End-to-End Verification

1. Log into web at http://localhost:5173
2. Go to **Connect App** → generate API key
3. In Flow iOS Settings, paste endpoint URL + API key
4. Capture a conversation → approve in Staging Vault
5. Watch **Company Brain** graph update in real time

## Stop

```bash
bash scripts/dev-down.sh
```

## Production Deploy

See [DEPLOY.md](DEPLOY.md).
