# Penlo Deployment Guide

## Brain → Railway

1. Create a [Railway](https://railway.app) project
2. Add **PostgreSQL** service (enable pgvector extension)
3. Deploy from `brain/` directory using [`railway.toml`](brain/railway.toml)
4. Set environment variables from [`brain/.env.example`](brain/.env.example):

| Variable | Required |
|----------|----------|
| `DATABASE_URL` | Yes (Railway Postgres URL, use `postgresql+asyncpg://`) |
| `JWT_SECRET_KEY` | Yes (32+ chars, `openssl rand -hex 32`) |
| `ANTHROPIC_API_KEY` | Yes |
| `PENLO_WEBHOOK_SECRET` | Yes (16+ chars) |
| `SLACK_SIGNING_SECRET` | Yes (16+ chars) |
| `CRM_WEBHOOK_SECRET` | Yes (16+ chars) |
| `SLACK_TOKEN_ENCRYPTION_KEY` | Yes (Fernet key) |
| `CORS_ALLOWED_ORIGINS` | Yes (your Vercel URL) |
| `PENLO_BASE_URL` | Yes (Railway backend URL) |
| `PENLO_FRONTEND_URL` | Yes (Vercel URL) |
| `ALLOW_COMPANY_SIGNUP` | `true` for self-service |

5. Run migrations: automatic on container start via `migrate.py`

```bash
bash scripts/deploy-railway.sh
```

## Web → Vercel

1. Import `penlo-hq/web` in [Vercel](https://vercel.com)
2. Set environment variables:

| Variable | Value |
|----------|-------|
| `VITE_API_URL` | Railway backend URL |
| `VITE_WS_URL` | Same host with `wss://` |
| `VITE_GOOGLE_CLIENT_ID` | Optional |

3. Deploy — `vercel.json` handles SPA routing

```bash
bash scripts/deploy-vercel.sh
```

## MCP (Cursor)

Add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "penlo": {
      "command": "python",
      "args": ["-m", "server"],
      "cwd": "/path/to/Penlo-hq/brain/mcp",
      "env": {
        "PENLO_API_TOKEN": "<token from brain/.env>",
        "PENLO_BACKEND_URL": "https://your-brain.railway.app"
      }
    }
  }
}
```

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
