# Penlo Deployment Guide

## Brain → Railway

1. Create a [Railway](https://railway.app) project
2. Add **PostgreSQL** service (enable pgvector extension)
3. Deploy from `brain/` directory using [`railway.toml`](brain/railway.toml)
4. Set environment variables from [`brain/.env.example`](brain/.env.example):

| Variable | Required | Notes |
|----------|----------|-------|
| `DATABASE_URL` | Yes | Railway Postgres URL, use `postgresql+asyncpg://` |
| `JWT_SECRET_KEY` | Yes | 32+ chars, `openssl rand -hex 32` |
| `ANTHROPIC_API_KEY` | Yes | LLM pipelines + briefings |
| `PENLO_WEBHOOK_SECRET` | Yes | 16+ chars |
| `SLACK_SIGNING_SECRET` | Yes | 16+ chars |
| `CRM_WEBHOOK_SECRET` | Yes | 16+ chars |
| `SLACK_TOKEN_ENCRYPTION_KEY` | Yes | Fernet key |
| `CORS_ALLOWED_ORIGINS` | Yes | Your Vercel URL (e.g. `https://app.penlo.ai`) |
| `PENLO_BASE_URL` | Yes | Railway backend URL (`https://…railway.app`) |
| `PENLO_FRONTEND_URL` | Yes | Vercel URL |
| `COOKIE_SAMESITE` | Yes (cross-origin) | `none` when web and API are on different domains |
| `ALLOW_COMPANY_SIGNUP` | Recommended | `true` for self-service design partners |
| `EXECUTOR_ENABLED` | Optional | `true` only when `GITHUB_TOKEN` + repo are configured |
| `GITHUB_TOKEN` | If executor | PAT with repo write access |
| `GITHUB_DEFAULT_REPO` | If executor | e.g. `penlo-hq/web` |

5. Migrations run automatically on container start via `migrate.py`

```bash
bash scripts/deploy-railway.sh
```

## Web → Vercel

1. Import `penlo-hq/web` in [Vercel](https://vercel.com)
2. Set environment variables:

| Variable | Value |
|----------|-------|
| `VITE_API_URL` | Railway backend URL (`https://…`) |
| `VITE_WS_URL` | Same host with `wss://` |
| `VITE_GOOGLE_CLIENT_ID` | Optional — Google OAuth |

3. Deploy — `vercel.json` handles SPA routing. CSP `connect-src` allows any `https:` / `wss:` origin so the dashboard can reach your Railway API without hardcoding hostnames.

```bash
bash scripts/deploy-vercel.sh
```

**Cross-origin cookies:** Brain must set `COOKIE_SAMESITE=none` and serve over HTTPS so the Vercel dashboard can send session cookies to Railway.

## MCP (Cursor / coding agents)

MCP uses **`PENLO_BACKEND_URL`** (not `PENLO_BASE_URL`) and a **service token** (not a dashboard `pb_live_` key).

| Token type | Created by | Used for |
|------------|------------|----------|
| Hex MCP token | `PENLO_API_TOKEN` in brain `.env` / `generate-env.sh` | MCP server, `query_brain` when mapped via `PENLO_MCP_TOKENS` |
| `pb_live_` key | Web **Connect App** | Flow iOS, meeting-capture, ingest |

Add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "penlo": {
      "command": "python",
      "args": ["-m", "server"],
      "cwd": "/path/to/Penlo-hq/brain/mcp",
      "env": {
        "PENLO_API_TOKEN": "<hex token from brain/.env>",
        "PENLO_BACKEND_URL": "https://your-brain.railway.app"
      }
    }
  }
}
```

Dispatch loop: `GET /api/v1/dispatches/approved` → build PR → `POST /api/v1/dispatches/{id}/complete`.

## Client ingest endpoints

| Client | URL to configure | Endpoint (appended by client) |
|--------|------------------|-------------------------------|
| Flow iOS | Brain base URL (`https://…`) | `POST /api/v1/ingest/penlo-brain` |
| meeting-capture | Brain base URL only | `POST /api/v1/ingest/standup` |
| Web Connect App | Shows full penlo-brain URL for Flow | — |

## CRM Integrations

Webhook endpoint: `POST /api/v1/ingest/webhooks/crm`

Headers:
- `X-Penlo-Signature` — HMAC-SHA256 of body
- `X-Penlo-Timestamp` — Unix timestamp
- `X-CRM-Workspace` — workspace ID registered in Brain

Supported `source` values: `linear`, `notion`, `hubspot`, or generic CRM.

Example payload:

```json
{
  "source": "linear",
  "event_type": "issue.updated",
  "properties": {
    "identifier": "ENG-42",
    "title": "Fix auth migration",
    "state": { "name": "In Progress" }
  }
}
```
