# Merge guide — which PRs to merge (June 2026)

**For reviewers:** merge **only** the four PRs in the green table below, in order. Other open PRs can stay open for history/reference — just don't merge them.

After merging all four, a fresh clone + `main` in each repo matches Sanjoy's local working tree (excluding local-only `.env` files).

---

## ✅ Merge these (in order)

| Step | Repo | PR | Branch |
|------|------|-----|--------|
| 1 | [workspace](https://github.com/penlo-hq/workspace) | **[#1](https://github.com/penlo-hq/workspace/pull/1)** | `fix/smoke-e2e-signup-payload` |
| 2 | [brain](https://github.com/penlo-hq/brain) | **[#16](https://github.com/penlo-hq/brain/pull/16)** | `feat/ghost-reviewer-mcp` |
| 3 | [web](https://github.com/penlo-hq/web) | **[#12](https://github.com/penlo-hq/web/pull/12)** | `feat/dashboard-lan-dev-and-signup` |
| 4 | [flow](https://github.com/penlo-hq/flow) | **[#4](https://github.com/penlo-hq/flow/pull/4)** | `feat/onboarding-lan-dev-and-sync` |

**meeting-capture** — no open PR; `main` is current.

---

## 📁 Open for reference — do NOT merge

These PRs remain open but are **older or duplicate** work. Merging them would miss the latest code or create conflicts.

| Repo | PR | Merge instead | Why |
|------|-----|---------------|-----|
| web | [#11](https://github.com/penlo-hq/web/pull/11) | **#12** | #12 contains all of #11's commits plus the latest dashboard/signup/LAN work |
| flow | [#3](https://github.com/penlo-hq/flow/pull/3) | **#4** | #4 contains all of #3's commits plus onboarding and LAN Brain fixes |

---

## ⏸️ Closed / unrelated

| Repo | PR | Notes |
|------|-----|-------|
| brain | [#17](https://github.com/penlo-hq/brain/pull/17) | Separate marketing-site work; not part of this merge batch |

---

## Verify after merge

From a monorepo root with all repos cloned:

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

## What each canonical PR contains

### workspace #1
Smoke-e2e signup payload fix, this merge guide, and `LOCAL_CLIENTS.md`.

### brain #16
Ghost Reviewer MCP, Redis WebSocket pub/sub, graph hygiene, dispatch executor + GitHub fields, timeline API, penlo-brain ingest hardening, MCP claim/report tools.

### web #12
Dashboard UI (dispatch, drafts, graph, permissions, tasks, timeline, Slack), company signup error handling, Vite `host: true` for LAN phone testing.

### flow #4
Onboarding flow, LAN Enterprise Brain connectivity (ATS + local network), faster connection test, vault/dispatch/briefing/sync improvements.

See [LOCAL_CLIENTS.md](./LOCAL_CLIENTS.md) for Flow iOS and meeting-capture setup after merge.
