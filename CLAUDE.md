# CLAUDE.md — root

JOBBees: Australian peer-to-peer task marketplace. Mobile-first, Node/NestJS backend, Next.js admin + web, Postgres + pgvector, Redis, Stripe Connect.

## Read these before doing any real work

1. **`PROJECT_CONTEXT.md`** — full architecture, conventions, compliance, AI usage, decisions. Load this first in every session.
2. **`docs/sprints/PLAN.md`** — master 13-sprint plan (Sprint 0 + 12 build sprints). Tells you which sprint is current and what's in scope.
3. **`docs/sprints/sprint-NN-<theme>.md`** — the current sprint's detail doc. Inventory rows, day-by-day plan, DoD, demo script, risks. **Every coding session starts from a feature row listed in the current sprint.**
4. The **scope tracker** (local `inventory/` folder, gitignored) — the 522-row inventory CSV referenced by ID throughout sprint docs. May not be present in fresh clones; the sprint docs are the authoritative-enough scope per sprint.
5. The `apps/<surface>/CLAUDE.md` for whichever app you're touching.

## Tech stack (locked, do not re-litigate)

- Backend: Node 24 + TypeScript 5.9 + NestJS 11 + Prisma 5.22 + PostgreSQL 16 (with pgvector) + Redis + BullMQ + Socket.IO (single-node at MVP)
- Mobile: Flutter + Riverpod + go_router + dio
- Admin + Web: Next.js 16 (App Router) + React 19 + shadcn/ui + Tailwind 4
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
13. **Do not bump major versions of dependencies.** Patch + minor versions only, batched monthly via Dependabot. Major bumps (e.g., ESLint v9 → v10, TS v5 → v6, Prisma v5 → v6, NestJS v10 → v11) require: (a) explicit human decision, (b) ADR documenting breaking changes + migration steps, (c) testing in isolation in a feature branch. Applies to humans AND any AI assistant editing this repo. Do not run `pnpm update --latest` during MVP build. See `.github/dependabot.yml` for the policy.

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
- Sprint plan + per-sprint scope: `docs/sprints/` (start with `PLAN.md`, then the current sprint's detail doc)
- Architecture decisions: `docs/adrs/` (001-008 currently)
- IT audit docs: `docs/audit/`
- Brand colors + UI principles: `docs/brand/` (Flutter theme files: `apps/mobile/lib/theme/`)
- Coverage tracker: `./scripts/coverage.sh` (reads gitignored inventory CSV)
- Local Postgres + Redis: `pnpm docker:up` (reads `ops/docker/dev.yml`)
- Database schema: `packages/prisma/schema.prisma`
- Security tooling: `ops/security/semgrep-rules.yml`, `.claude/skills/security-review/SKILL.md`

## Dos and Don'ts — quick reference

These distil the rules above into a scannable form. When in doubt, prefer the more conservative option.

### Security ✅ Do

- ✅ Validate every input via class-validator DTO or Zod (no `body: any`)
- ✅ Wrap external LLM calls in `redactPii()` before sending
- ✅ Verify webhook signatures BEFORE any DB write
- ✅ Pass `idempotencyKey` to every Stripe mutating call
- ✅ Apply `@UseGuards(JwtAuthGuard)` + `@Roles(...)` on every non-public route
- ✅ Use `Prisma.sql` template tag for raw queries (never string interpolation)
- ✅ Hash passwords with `argon2id` (not bcrypt, not sha256)
- ✅ Read all config via `ConfigService` (never `process.env.X` directly outside config)
- ✅ Run the `security-review` skill on every PR touching auth/payment/tax/kyc/ai
- ✅ Write to `AuditLog` on every money, role, KYC change

### Security ❌ Don't

- ❌ Don't hardcode API keys, JWT secrets, or any credential — gitleaks will block, but don't write them in the first place
- ❌ Don't log PII (email, phone, full name, address, ABN, document numbers, bank info) — use `[REDACTED:email]` placeholders or `pino.redact`
- ❌ Don't store passwords client-side, in localStorage, or in plain text anywhere
- ❌ Don't use `Math.random()` for security-sensitive values — use `crypto.randomBytes()`
- ❌ Don't use `eval()` or `Function()` constructor on user input
- ❌ Don't store ID document numbers (passport, license) — the document image is enough for audit if you must store
- ❌ Don't trust dates from client — always validate against server time
- ❌ Don't disable HTTPS/TLS anywhere (dev included)
- ❌ Don't write your own crypto — use established libraries (`argon2`, `crypto`, `jose`)
- ❌ Don't suppress ESLint or Semgrep without a written justification in the PR

### Clean code ✅ Do

- ✅ Keep functions small (< 50 lines), single-purpose
- ✅ Use early returns over deeply nested `if/else`
- ✅ Prefer composition over inheritance
- ✅ Name variables for what they hold (`acceptedBid`, not `b`)
- ✅ Comment WHY, not WHAT — code shows what, comments explain why
- ✅ Write tests in the same PR as the code they cover
- ✅ Use `const` over `let`, never `var`
- ✅ Handle errors explicitly — catch, decide, log/rethrow
- ✅ Use TypeScript strict mode everywhere
- ✅ Delete dead code — git remembers it

### Clean code ❌ Don't

- ❌ Don't use `any` (use `unknown` if truly unknown + narrow before use)
- ❌ Don't comment-out code — delete it, git remembers
- ❌ Don't write god functions / god classes (> 200 lines)
- ❌ Don't catch errors without handling them (`catch (e) {}` is a sin)
- ❌ Don't use `console.log` in committed code — use the project's logger (`pino`)
- ❌ Don't use magic numbers (use named constants)
- ❌ Don't use `// @ts-ignore` without a written justification
- ❌ Don't write tests after the fact ("I'll add tests later" = never)
- ❌ Don't introduce a new utility library without checking what's already in the repo
- ❌ Don't roll your own date parsing — use `date-fns` (already in deps)

### Workflow ✅ Do

- ✅ Branch per work item: `feat/<short-name>` (one feature per branch)
- ✅ Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, etc.
- ✅ Small PRs (< 400 LOC ideal, 800 max)
- ✅ One feature per PR, no drive-by refactors
- ✅ Use **plan mode** for any task above ~30 minutes (`Shift+Tab` or `/plan`)
- ✅ Run the security-review skill on sensitive paths
- ✅ Reference the inventory row ID in the PR description ("Closes inventory row #234")
- ✅ Update the inventory CSV column 9 to `done [sprint-N, PR#nn]` after merge
- ✅ Update docs in the same PR as the code (PROJECT_CONTEXT.md, ADRs, audit docs, sprint docs)

### Workflow ❌ Don't

- ❌ Don't push directly to `main` — branch protection should block, but don't try
- ❌ Don't merge if CI is red
- ❌ Don't skip human review on payment / tax / PII PRs (CLAUDE.md rule 2 — non-negotiable)
- ❌ Don't introduce a new dependency without checking license + maintenance + size
- ❌ Don't bump major versions without an ADR (CLAUDE.md rule 13)
- ❌ Don't run `pnpm update --latest` during MVP build
- ❌ Don't add features outside the current sprint's scope — backlog them for later
- ❌ Don't use `git commit --no-verify` except for documented exceptions (initial scaffold commits, docs-only)
- ❌ Don't leave commented-out code or dead branches in a PR

### AI assistant behaviour ✅ Do (applies to Claude Code AND human)

- ✅ Read `PROJECT_CONTEXT.md` + current sprint doc + this file before any non-trivial work
- ✅ Use plan mode for tasks > 30 min — review the plan before writing code
- ✅ Invoke the appropriate skill (stripe-payment, au-tax, pgvector-match, tier0-dispute, multimodal-extraction, security-review) when touching the matching domain
- ✅ Refuse to bump major dependency versions
- ✅ Surface any uncertainty rather than guess (e.g., AU tax law, Stripe Connect specifics)
- ✅ Quote sources / docs when stating a fact that affects compliance

### AI assistant behaviour ❌ Don't (applies to Claude Code AND human)

- ❌ Don't hallucinate AU tax requirements — the `au-tax` skill is flagged "high hallucination risk" for a reason
- ❌ Don't assume Stripe Connect specifics from training data — read current docs
- ❌ Don't auto-bump dependency versions during edits
- ❌ Don't ship payment code without a human reviewer reading every line (CLAUDE.md rule 2)
- ❌ Don't generate test data with realistic PII patterns (use clearly-fake `@example.com`, AU `+61400000000` test format)
- ❌ Don't write code that bypasses any of the hard rules above

## Pre-flight checklist for any PR

Before opening a PR, run through:

- [ ] Does this match a feature row in the current sprint's detail doc?
- [ ] Does the PR title use Conventional Commits format?
- [ ] Does it close (or progress) a specific inventory row?
- [ ] Are tests included for the happy path + at least one error case?
- [ ] If touching auth / payment / tax / kyc / ai / webhooks: has the `security-review` skill been run?
- [ ] If touching the Prisma schema: do FKs have indexes? Money fields `Int` cents? Soft delete on user-facing entities?
- [ ] If introducing a new pattern / convention: is an ADR drafted?
- [ ] If touching docs/audit/\*: is the "Last reviewed" date updated?
- [ ] Have you reviewed the PR template's section-specific checks (payment, tax, KYC, etc.)?
- [ ] Has CI passed locally before pushing?
