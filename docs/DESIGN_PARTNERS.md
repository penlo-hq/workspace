# Design Partner Playbook

Penlo's first 5 design partners validate product-market fit for startup context management.

## Ideal design partner profile

- **Stage:** Seed to Series A (5–30 people)
- **Pain:** Context loss in Slack/meetings; new hires ask the same questions weekly
- **Stack:** Uses Slack daily; engineers use Cursor or Claude Code
- **Champion:** Founder or Head of Engineering willing to give weekly feedback

## Onboarding checklist (Week 1)

1. **Deploy Penlo** — Brain on Railway, web on Vercel (see [DEPLOY.md](../DEPLOY.md))
2. **Self-service signup** — `ALLOW_COMPANY_SIGNUP=true` on Brain
3. **Connect Slack** — Admin → Slack Settings → OAuth install → enable 2–3 channels
4. **Pair Flow iOS** — Connect App → generate API key → configure in Flow Settings
5. **Install meeting capture** — Load `meeting-capture/` Chrome extension for Meet/Zoom
6. **First query** — Ask: "What do we know about [recent project]?"
7. **Schedule weekly 30min feedback call**

## Success metrics (track per partner)

| Metric | Target (Week 4) |
|--------|-------------------|
| Active users | ≥ 3 per company |
| Ingestion events/week | ≥ 20 |
| Queries/week | ≥ 10 |
| Query thumbs-up rate | ≥ 60% |
| Slack channels connected | ≥ 2 |

## Slack as primary ingest

Slack is the highest-volume capture surface for startups:

1. Admin connects workspace via `/slack-settings`
2. Enable channels: `#engineering`, `#product`, `#general`
3. Messages flow → LangGraph ingestion → graph updates in real time
4. `/brain` slash command for in-Slack queries

## Feedback collection

- Query feedback (👍/👎) in Ask the Brain — stored in `query_feedback` table
- Langfuse traces for query quality analysis
- Weekly call notes in a shared doc

## Conversion path

Design partner → paid Team plan ($25/user/mo) when:
- ≥ 3 weekly active users
- Champion confirms "we'd be worse off without it"
- Willing to be a reference customer

## Outreach template

> We're building Penlo — a company memory layer for startups. It captures context from Slack and conversations, builds a living knowledge graph, and lets you query it in plain English.
>
> We're looking for 3–5 design partners to use it free for 8 weeks in exchange for weekly feedback. Interested in a 20-minute demo?
