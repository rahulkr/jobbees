# CLAUDE.md — root

JOBBees: Australian peer-to-peer task marketplace. Mobile-first, Node/NestJS backend, Next.js admin + web, Postgres + pgvector, Redis, Stripe Connect.

## Read these before doing any real work

1. **`PROJECT_CONTEXT.md`** — full architecture, conventions, compliance, AI usage, decisions. Load this first in every session.
2. The **scope tracker** (local `inventory/` folder, gitignored) or your team's work-tracking system — every coding session starts from a defined work item there.
3. The `apps/<surface>/CLAUDE.md` for whichever app you're touching.

## Tech stack (locked, do not re-litigate)

- Backend: Node 22 + TypeScript + NestJS + Prisma + PostgreSQL 16 (with pgvector) + Redis + BullMQ + Socket.IO (single-node at MVP)
- Mobile: Flutter + Riverpod + go_router + dio
- Admin + Web: Next.js 14 (App Router) + shadcn/ui + Tailwind
- Payments: Stripe + Stripe Connect Express + Stripe Identity
- LLMs: Gemini Flash (high-volume) + Claude Sonnet (disputes, admin co-pilot) + OpenAI embeddings (1536 dims)
- Hosting: Azure (App Service, Postgres Flexible, Cache for Redis, Blob, Key Vault, App Insights)
- CI/CD: GitHub Actions. IaC: Terraform.
- Monorepo: pnpm workspaces + Turborepo.

## Hard rules — never violate

1. **Never commit secrets.** Gitleaks pre-commit blocks this; CI also scans. Use `.env.local` for dev, Key Vault for staging/prod.
2. **All payment / tax / PII code requires manual review.** Even if you authored it via AI, read every line. This is the biggest blast-radius area in the project.
3. **Idempotency on every mutating endpoint.** Required `Idempotency-Key` header, Redis-backed cache with 24h TTL.
4. **GST / RCTI / ATO sharing-economy reporting is non-negotiable.** Australian compliance. Engage the tax advisor before shipping payment code.
5. **All money in cents (integer).** Never `Decimal` or `Float`.
6. **All times UTC in DB, Australia/Sydney in UI.** Never store local time.
7. **All IDs as cuid2 strings.** Set in app code via `@paralleldrive/cuid2`. Never `Int` autoincrement, never `cuid()` (cuid1).
8. **Foreign key indexes are manual.** Prisma does not auto-add them. Always add `@@index([fkField])`.
9. **PII redacted before any external LLM call.** Use the redaction layer in `apps/api/src/modules/ai/pii.ts`.
10. **Soft delete on user-facing entities** (`deletedAt`). Filter `where: { deletedAt: null }` by default — use the Prisma extension we have for this.
11. **Australia (`AU`) hardcoded as default country.** Schema is multi-country-ready (see `Country` model) but logic is AU-only at MVP.
12. **Auto-migration off in prod.** Only CI runs `prisma migrate deploy`. App startup does not migrate.

## Workflow

- Branch per work item: `feat/<short-name>` (e.g. `feat/ranked-feed`)
- Conventional Commits: `feat:`, `fix:`, `chore:`, etc.
- Use **plan mode** (`Shift+Tab` or `/plan`) for any task above ~30 minutes. Review the plan before writing code.
- Run tests after edits. Configure auto-test in `.claude/settings.json`.
- Run the `security-review` skill on every PR touching auth, payments, or PII.

## Custom skills available (in `.claude/skills/`)

- `stripe-payment` — invoked when touching payments. Payment state machine, capture window, idempotency, refunds, RCTI triggers.
- `au-tax` — invoked when touching tax / RCTI / ATO / GST. **High AI-hallucination risk — review every line.**
- `pgvector-match` — invoked for matching / ranking. Embedding model, cosine queries, ranked-feed weighted blend.
- `tier0-dispute` — invoked for dispute mediator work. System prompt, evidence aggregation, output schema, escalation rules.
- `multimodal-extraction` — invoked for vision-based task extraction from poster photos. Model tier (Flash → Pro fallback, never Opus), preprocessing, schema, cost guardrails.

## Pointers

- Full context: `PROJECT_CONTEXT.md`
- Architecture decisions: `docs/adrs/`
- IT audit docs: `docs/audit/`
- Local Postgres + Redis: `pnpm docker:up` (reads `ops/docker/dev.yml`)
- Database schema: `packages/prisma/schema.prisma`
