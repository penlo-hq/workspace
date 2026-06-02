# Penlo Local Development Setup

Run all commands from the **monorepo root** (`Penlo-hq/`), not from `workspace/scripts/`.

## Prerequisites

- **Docker** (Docker Desktop or `brew install colima docker docker-compose`)
- **Colima** (if not using Docker Desktop): `colima start`
- **Node.js 20+** (for web dashboard)
- **Python 3.11** (for host-side scripts: seed, create_admin)
- **Xcode 16+** (for Flow iOS app)
- **Chrome** (for meeting-capture extension, optional)

## Quick Start

```bash
# 1. Start brain backend + Postgres (generates brain/.env and web/.env.local)
bash scripts/dev-up.sh

# 2. Start web dashboard
cd web && npm install && npm run dev
# → http://localhost:5173

# 3. Create your first account (pick one path below)

# 4. Open Flow iOS app (optional)
open flow/flow.xcodeproj
```

## First account — Path A (recommended)

`scripts/generate-env.sh` sets `ALLOW_COMPANY_SIGNUP=true`, so you can self-serve:

1. Open http://localhost:5173/signup
2. Create your company and admin account
3. Log in → **Connect App** → generate a `pb_live_` API key

## First account — Path B (demo seed)

For a pre-populated demo company with sample graph data:

```bash
cd brain/backend
python3.11 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

PENLO_ALLOW_SEED=1 python scripts/seed.py
ADMIN_PASSWORD='your-secure-password' python scripts/create_admin.py
# Default email: admin@demo.penlo.ai (override with ADMIN_EMAIL=...)
```

Or use the seeded demo user printed by `seed.py` (`alex@demo.penlo.ai`).

## Flow iOS (simulator or device)

1. Web → **Connect App** → copy API key
2. Flow → Settings → Enterprise Brain URL: `http://localhost:8000` (simulator) or `http://<your-mac-lan-ip>:8000` (physical device)
3. Paste `pb_live_` key → tap **Test Connection**
4. Capture a conversation → approve in **Staging Vault**
5. Watch **Company Brain** update in the web dashboard

## Meeting Capture (Chrome extension)

1. Chrome → `chrome://extensions` → **Developer mode** → **Load unpacked** → select `meeting-capture/`
2. Extension popup → **Brain base URL**: `http://localhost:8000` (origin only, not the full ingest path)
3. Paste the same `pb_live_` key from **Connect App**
4. Join a Google Meet or Zoom call with captions enabled — transcripts post to `POST /api/v1/ingest/standup` on meeting end

See [meeting-capture/README.md](meeting-capture/README.md) for details.

## MCP (Cursor / coding agents)

After `dev-up.sh`, note the MCP token printed by `generate-env.sh`. Add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "penlo-brain": {
      "command": "docker",
      "args": ["exec", "-i", "brain-backend-1", "python", "-m", "mcp.server"],
      "env": {
        "PENLO_BACKEND_URL": "http://localhost:8000",
        "PENLO_API_TOKEN": "<token-from-generate-env>"
      }
    }
  }
}
```

The MCP token is a hex service token (not a `pb_live_` dashboard key). Use **Connect App** keys for Flow and meeting-capture.

## End-to-End Verification

1. Log into web at http://localhost:5173
2. **Connect App** → generate API key
3. Flow: Test Connection → Staging Vault sync → graph node appears
4. Web: **Ask Brain** returns an answer
5. (Optional) meeting-capture: join a call → check brain logs for standup ingest

## Stop

```bash
bash scripts/dev-down.sh
```

## Production Deploy

See [DEPLOY.md](DEPLOY.md).
