# Sprint 0 — Foundation, AI setup, security tooling

**Dates:** Mon 1 Jun → Fri 12 Jun 2026 (10 working days)
**Theme:** Get every prerequisite in place so Sprint 1 can be pure feature work from day one.
**Hours spent:** ~70 (foundation work — not billed against the v1.1 build budget)
**Status:** In progress. Wraps Friday 12 Jun.

## Why a Sprint 0?

Sprint 0 isn't a feature sprint. It's the prerequisite plumbing — the choices and structures that have to be made *once*, *up front*, and live with you for the life of the project. Trying to do this work mid-sprint while also shipping features is how you ship the wrong architecture and discover it in Sprint 6.

Specifically, Sprint 0 covers:

- The monorepo shape (apps, packages, layout)
- The data model (Prisma schema, migration baseline)
- The AI tooling layer (custom Claude Code skills, prompt patterns)
- The security gates (Semgrep rules, PR template, gitleaks, audit doc templates)
- The repo on GitHub (initial commit, CI, branch protection)
- The plan itself (this folder, the inventory tracker, the coverage script)

Then Sprints 1-12 spend the ~945-hour build budget on actual features without re-litigating any of the above.

## What's been delivered

### Architecture + repo

- Monorepo: pnpm workspaces + Turborepo
- 4 apps: `apps/mobile` (Flutter), `apps/api` (NestJS), `apps/admin` (Next.js), `apps/web` (Next.js)
- 4 packages: `packages/prisma`, `packages/types`, `packages/tsconfig`, `packages/eslint-config`
- Root config: ESLint v9 flat config (base + per-app), Prettier, lefthook, turbo.json, tsconfig.base.json
- Pre-commit hooks: gitleaks, ESLint, Prettier, TypeScript typecheck
- Pre-push hook: test
- Local Docker: Postgres 16 + pgvector extension, Redis 7, init scripts

### Data model

- Prisma schema with 9 first-class models: `Country`, `User`, `UserSkill`, `Category`, `Task`, `TaskPhoto`, `TaskQuestion`, `Bid`, `Review`, `AuditLog`
- Enums: `UserRole`, `CategoryType`, `TaskStatus`, `BidStatus`, `PaymentState`, `DisputeState`, `KycStatus`, `ConnectStatus`
- Conventions: cuid2 IDs, integer cents, soft delete on user-facing entities, UTC times, `countryCode` defaulting to AU
- pgvector columns on User + Task (1536-dim, ready for OpenAI embeddings)
- Migrations: `000_enable_pgvector` (raw SQL for extension), `20260602102440_init` (full schema)
- Seed data: 1 super-admin + 5 posters + 10 taskers + 20 tasks + 39 bids
- `FUTURE MODELS` comment block in `schema.prisma` lists every model needed by IN features but not yet built (Payment, TaxInvoice, Rcti, Cancellation, Dispute, NotificationPreference, ServiceArea, AdminTotp, RefreshToken, etc.) — nothing falls through

### Architecture Decision Records

- ADR 001 — Monorepo and stack choices
- ADR 002 — Database conventions (cuid2, integer cents, soft delete, UTC)
- ADR 003 — Multi-country readiness (Country table, countryCode field, AU-only at MVP)
- ADR 004 — Category types (TRANSACTIONAL vs LEAD enum, MVP all TRANSACTIONAL)

ADRs to land before end of Sprint 0:

- ADR 005 — KYC strategy (Didit vs manual) — **pending client decision**
- ADR 006 — Auth token storage (Bearer for mobile, HttpOnly cookie for web/admin) — **decision in Sprint 1 D1, but ADR can land Sprint 0 with default**

### IT audit documentation (19 docs)

`docs/audit/`:

- access-control-policy.md
- architecture-overview.md
- audit-log-policy.md
- australian-compliance.md
- backup-recovery-procedure.md
- bcp-dr-plan.md
- change-management.md
- data-classification-policy.md
- data-flow-diagram.md
- data-retention-policy.md
- dsr-process.md
- edge-security.md (Cloudflare Pro vs Azure Front Door Premium decision framework)
- encryption-policy.md
- incident-response-plan.md
- privacy-policy.md
- secure-sdlc.md
- security-by-stage.md (defense-in-depth map across 7 lifecycle stages)
- vendor-list.md
- vulnerability-management.md

### Custom Claude Code skills (6 skills)

`.claude/skills/`:

- **`stripe-payment`** — payment state machine, capture window, idempotency, refunds, RCTI triggers
- **`au-tax`** — GST + RCTI + ATO sharing-economy reporting. Flagged for high AI-hallucination risk — every line requires manual review
- **`pgvector-match`** — embedding model, cosine queries, ranked-feed weighted blend
- **`tier0-dispute`** — system prompt, evidence aggregation, output schema, escalation rules
- **`multimodal-extraction`** — vision-based task extraction (Flash → Pro fallback, never Opus), preprocessing, cost guardrails
- **`security-review`** — project-specific security review with 30+ JOBBees rules (auto-invokes on changes to auth/payment/tax/kyc/ai/webhook/schema paths)

### Security tooling

- **Semgrep**: 18 JOBBees-specific rules in `ops/security/semgrep-rules.yml` (money type, hardcoded secrets, raw query interpolation, soft-delete filter, LLM redaction, audit log immutability, cuid1/autoincrement IDs, GST math, process.env access, etc.) + integration with registry rules (typescript / nestjs / owasp-top-ten / secrets)
- **CI workflow**: `.github/workflows/semgrep.yml` runs on every PR + daily on main, uploads SARIF to GitHub Code Scanning
- **PR template**: `.github/pull_request_template.md` with section-by-section reviewer checklist (auth, payment, tax, KYC, AI, schema, webhooks, env, infra, docs)
- **Pre-commit**: gitleaks (secret scan), ESLint, Prettier, TypeScript typecheck
- **Pre-push**: full test suite

### Dependency policy

- `.github/dependabot.yml`: monthly batched minor + patch PRs only, major bumps explicitly ignored. Security advisories still flow through GitHub's separate Dependabot security alerts (always on).
- CLAUDE.md rule #13: ban major dep bumps without an ADR. Applies to humans AND AI assistants.

### Plan + tracking

- `docs/sprints/PLAN.md` — 12-sprint master plan (Mon 15 Jun → Fri 27 Nov 2026), vertical slices, weekly Friday demos
- `docs/sprints/sprint-01-onboarding-and-auth.md` — Sprint 1 detail (this is the next sprint)
- `docs/sprints/sprint-00-foundation-and-setup.md` — this doc
- `scripts/coverage.sh` — Friday CSV → coverage % report
- `inventory/JOBBees_Feature_Inventory.csv` — 522-row inventory (gitignored, local-only, source of truth for what's IN/IN★/POST/THIN/DROP/MANUAL)

### Repo on GitHub

- https://github.com/rahulkr/jobbees
- Initial commit pushed (`chore: initial scaffold for JOBBees AU task marketplace`)
- Author email + name configured locally
- Branch: `main` (default + tracked from origin)
- Branch protection: TODO before Sprint 1 D1 (require 1 reviewer, all CI checks green, no merging if CRITICAL security findings open)

## What's still to do before Sprint 0 wraps (D8–D10)

### Decisions needed (client side)

| Decision | Who | Needed by | Default if not decided |
| --- | --- | --- | --- |
| KYC vendor: Didit vs manual review queue | Client | Fri 12 Jun EOD | Manual review queue |
| Auth-token storage strategy (per-surface) | Eng lead + client | Mon 15 Jun (Sprint 1 D1) | Bearer for mobile, HttpOnly cookie for web/admin |
| Cloudflare Pro vs Azure Front Door Premium (for Sprint 10) | Client | mid-Sprint 9 (procurement lead time) | Cloudflare Pro ($25/mo) |
| Tax advisor engagement | Client | mid-Sprint 5 | Engage anyway |

### Things to set up (operational side)

- [ ] OAuth client IDs: Google + Apple (Apple needs paid Developer Program enrolment — start now, ~3 day approval)
- [ ] Notifyre alpha sender ID application (`JOBBEES`) — submitted to Notifyre, allow 5-7 business days
- [ ] SendGrid account (free tier OK for dev) — domain verification can wait until S10
- [ ] Stripe Australia account in test mode (free) — can start now, validates as part of S2 work
- [ ] Stripe Connect onboarding application — 5-10 business days approval, start now
- [ ] (Optional) Didit sandbox account if KYC decision = Didit — free, instant
- [ ] Branch protection on `main` (require 1 reviewer + all CI checks)
- [ ] Enable Dependabot security alerts in repo settings → Security & analysis

## Sprint 0 wrap-up demo (Fri 12 Jun) — script

This demo establishes credibility with the client: it shows everything that's been built isn't a coding sprint but a foundation that *enables* coding sprints. Aim for a 5-7 minute screen-cast.

```
00:00 — "Welcome to Sprint 0 wrap. This sprint was foundation work — what
        the team needs in place before feature-building can start. Here's
        what we've put down so we can move fast in Sprint 1."

00:20 — Open VS Code on the repo. Show the file tree:
        apps/  → mobile, api, admin, web
        packages/ → prisma, types, tsconfig, eslint-config
        docs/ → adrs/, audit/, sprints/
        ops/ → docker/, security/
        .claude/ → 6 custom AI skills
        .github/ → CI workflows, PR template, Dependabot
        scripts/ → coverage script

00:50 — Show packages/prisma/schema.prisma. Scroll through models. Point
        out: cuid2 IDs, integer cents, soft delete, pgvector columns,
        FUTURE MODELS comment block listing what's coming.

01:30 — Open docs/adrs/. Show the 4 ADRs. Briefly explain "we record every
        important decision so future-team doesn't re-litigate."

02:00 — Open docs/audit/. Show the 19 IT audit docs. "These are what the
        client's IT auditor will need on day one of post-launch review.
        Templates are filled in for everything we know now, with TODO
        markers where the answer comes later in the build."

02:30 — Open .claude/skills/. Show the 6 skills. "When the AI is editing
        sensitive code — payments, tax, KYC — these skills auto-invoke
        with project-specific rules that no generic tool can know."

03:00 — Show .github/pull_request_template.md briefly — section-by-section
        checklist.

03:20 — Open ops/security/semgrep-rules.yml. "18 rules that run on every
        PR. They catch JOBBees-specific bugs — money stored as Decimal,
        missing idempotency keys, etc."

03:50 — Open docs/sprints/PLAN.md. Show the 12-sprint table. "Every
        Friday at our call, you'll see one of these rows light up."

04:20 — Run ./scripts/coverage.sh. Output: 0% complete (expected — no
        features delivered yet). "By end of Sprint 1, this will say ~12%."

04:40 — Show docs/sprints/sprint-01-onboarding-and-auth.md. "Sprint 1
        starts Monday. The day-by-day plan is in here. Demo script is
        ready. Inventory rows are scoped."

05:10 — Open github.com/rahulkr/jobbees in browser. Show the repo is
        live, the README, the first commit.

05:30 — Stoplight summary:
        ✅ Green: monorepo, schema, ADRs, audit docs, security tooling,
                 Claude skills, CI, repo on GitHub, plan locked.
        🟡 Yellow: pending decisions — KYC vendor (need by EOD today),
                   auth-token strategy (need by Monday).
        🔴 Red: none.

05:50 — "Next sprint starts Monday 15 Jun. We need from you today:
        (1) KYC vendor decision — Didit (vendor) or manual review queue;
        (2) sign-off on the Sprint 1 demo script — does it cover what
        you want to see Friday 26 Jun?"

06:00 — End. Send link to demo video + this doc + PLAN.md.
```

## Why this approach worked

A foundation sprint is the most under-valued kind of sprint. Three things have to be true for it to pay off:

1. **You make decisions you'll inherit.** Sprint 0 ADRs decided the database conventions, multi-country approach, category types, monorepo structure, and ESLint config. Those will affect every PR for the next 24 weeks.
2. **You build the tooling you'll lean on.** The 6 custom Claude Code skills + 18 Semgrep rules + PR template are how the project stays correct *while* moving fast. The cost is one sprint up front; the benefit is every sprint after.
3. **You set the cadence.** The 12-sprint plan + Friday demo ritual + coverage script + inventory tracker establish the rhythm. Once a rhythm exists, sprints execute themselves.

If Sprint 0 hadn't happened, Sprint 1 would have been: "we need to figure out the schema → wait, what ID format are we using? → wait, do we need a security review skill? → wait, where do ADRs live?" Sprint 1 starting on a foundation means it goes straight to: open the splash screen file, start coding.

## Hand-off to Sprint 1

Monday 15 Jun, 9:00am Sydney time:

1. Open `docs/sprints/sprint-01-onboarding-and-auth.md`
2. Confirm KYC decision recorded in ADR 005
3. Confirm auth-token decision recorded in ADR 006
4. `git checkout -b feat/auth-rotation` for the first PR (per the day-by-day plan in sprint-01 doc)
5. Start with `packages/prisma`'s new tables (RefreshToken, EmailVerificationToken, PasswordResetToken)
6. The rest of the day-by-day plan is in sprint-01-onboarding-and-auth.md

The PR template, security gates, Semgrep rules, and skill auto-invocation all already work. Just open a PR — everything runs.

## Lessons for the rest of the project

Things that surprised me in Sprint 0 (useful context for future sprints):

- **The auto-updater problem is real.** Multiple times during Sprint 0, dep versions got auto-bumped to bleeding-edge (ESLint 10, TS 6, Prisma 7) and broke the build. CLAUDE.md rule #13 + Dependabot policy now formalises "no major bumps without ADR". If something similar happens later in the project, the pattern is: pin, document why, move on.
- **Workspace consolidation matters.** `create-next-app` put nested `pnpm-workspace.yaml` files inside `apps/admin` and `apps/web` which confused pnpm. We consolidated to the root. If a future scaffolding tool does similar, expect to hunt for nested configs.
- **Bash sandbox on macOS Application Support paths is fragile.** Worked around by relying on file tools + asking the user to run commands. Don't depend on bash for this project's path layout.
- **The inventory CSV is the source of truth.** It's gitignored intentionally — it contains commercial scope decisions that don't belong in the public-ish repo. Friday coverage script reads it, no other system needs to.
