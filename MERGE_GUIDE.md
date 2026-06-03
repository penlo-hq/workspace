# Merge guide — canonical PRs (June 2026)

**For reviewers:** merge **only** the four PRs below, in order. Everything else in this org should stay closed.

These branches match Sanjoy's local working tree as of the commits listed. After merging all four, a fresh clone + checkout of `main` in each repo reproduces the same code (excluding local-only `.env` files).

---

## Merge order

| Step | Repo | PR | Branch |
|------|------|-----|--------|
| 1 | [workspace](https://github.com/penlo-hq/workspace) | **[#1](https://github.com/penlo-hq/workspace/pull/1)** | `fix/smoke-e2e-signup-payload` |
| 2 | [brain](https://github.com/penlo-hq/brain) | **[#16](https://github.com/penlo-hq/brain/pull/16)** | `feat/ghost-reviewer-mcp` |
| 3 | [web](https://github.com/penlo-hq/web) | **[#12](https://github.com/penlo-hq/web/pull/12)** | `feat/dashboard-lan-dev-and-signup` |
| 4 | [flow](https://github.com/penlo-hq/flow) | **[#4](https://github.com/penlo-hq/flow/pull/4)** | `feat/onboarding-lan-dev-and-sync` |

**meeting-capture** — no open PR; `main` is current.

---

## Do not merge (close if still open)

| Repo | PR | Reason |
|------|-----|--------|
| web | [#11](https://github.com/penlo-hq/web/pull/11) | Superseded by **#12** (strict superset of commits) |
| flow | [#3](https://github.com/penlo-hq/flow/pull/3) | Superseded by **#4** (strict superset of commits) |
| brain | [#17](https://github.com/penlo-hq/brain/pull/17) | Unrelated website work; already closed |

---

## Verify after merge

From a monorepo root with all repos cloned, each repo's `main` should contain the merged PR branch tip:

```bash
cd workspace && git checkout main && git pull
cd ../brain && git checkout main && git pull
cd ../web && git checkout main && git pull
cd ../flow && git checkout main && git pull
```

Smoke test (after `bash scripts/dev-up.sh`):

```bash
bash scripts/smoke-e2e.sh
```

---

## Local-only files (never committed)

These exist on dev machines only — do **not** expect them in git:

- `brain/.env`, `brain/backend/.env`
- `web/.env.local`
- `flow/audio-pipeline/.env`

Generate dev secrets with `bash scripts/generate-env.sh`.

---

## What each PR contains

### workspace #1
Fixes `scripts/smoke-e2e.sh` signup payload field names (`admin_email`, `admin_password`, `admin_name`).

### brain #16
Ghost Reviewer MCP, Redis WebSocket pub/sub, graph hygiene, dispatch executor + GitHub fields, timeline API, penlo-brain ingest hardening, MCP claim/report tools.

### web #12
Dashboard UI (dispatch, drafts, graph, permissions, tasks, timeline, Slack), company signup error handling, Vite `host: true` for LAN phone testing.

### flow #4
Onboarding flow, LAN Enterprise Brain connectivity (ATS + local network), faster connection test, vault/dispatch/briefing/sync improvements.

See [LOCAL_CLIENTS.md](./LOCAL_CLIENTS.md) for Flow iOS and meeting-capture setup after merge.
