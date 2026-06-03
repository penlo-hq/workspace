# Penlo Workspace

Local development workspace for the Penlo platform. Clone this repo alongside the product repos:

```bash
mkdir penlo && cd penlo
git clone https://github.com/penlo-hq/workspace.git .
git clone https://github.com/penlo-hq/brain.git brain
git clone https://github.com/penlo-hq/web.git web
git clone https://github.com/penlo-hq/flow.git flow
git clone https://github.com/penlo-hq/meeting-capture.git meeting-capture
```

**Run scripts from the monorepo root** (`bash scripts/dev-up.sh`), not from `workspace/scripts/`.

See [SETUP.md](./SETUP.md) for the full local dev guide.

**Merging code?** See [MERGE_GUIDE.md](./MERGE_GUIDE.md) for the exact PRs to merge (canonical as of June 2026).

**Architecture:** See [ARCHITECTURE.md](./ARCHITECTURE.md) for the comprehensive platform architectural summary (external review document).

## API integration matrix

| Client | Auth | Base URL config | Endpoint |
|--------|------|-----------------|----------|
| **web** | Session cookies (`penlo_access`) | `VITE_API_URL`, `VITE_WS_URL` | `/api/v1/*` |
| **Flow iOS** | `Bearer pb_live_…` | Keychain Enterprise Brain URL | `POST /api/v1/ingest/penlo-brain` |
| **Flow iOS** | `Bearer pb_live_…` | Same brain host | `GET /api/v1/briefing`, `/api/v1/dispatches/*` |
| **meeting-capture** | `Bearer pb_live_…` | Extension popup: brain **base URL** | `POST /api/v1/ingest/standup` |
| **MCP** | `Bearer` hex service token | `PENLO_BACKEND_URL` | ingest, query, dispatches |

## Environment variable naming

| Variable | Used by |
|----------|---------|
| `VITE_API_URL` / `VITE_WS_URL` | web (Vite) |
| `PENLO_BASE_URL` / `PENLO_FRONTEND_URL` | brain backend |
| `PENLO_BACKEND_URL` / `PENLO_API_TOKEN` | MCP server |
| `penloBaseUrl` / `penloApiKey` | meeting-capture (chrome.storage) |

Dashboard `pb_live_` keys (Connect App) are for mobile and extension clients. MCP uses the hex token from `brain/.env`.
