---
name: security-review
description: Project-specific security review for JOBBees. Auto-invoke on changes to auth, payment, tax, KYC, AI, webhooks, controllers, Prisma schema, and env/config. Enforces JOBBees-specific rules (idempotency, money-in-cents, PII redaction, AU compliance) that generic SAST cannot know.
version: 1.0.0
last_reviewed: 2026-06-09
---

# Security Review (JOBBees)

This skill is a **JOBBees-specific** layered security check that runs alongside the generic security-review built-in. It enforces the rules in `CLAUDE.md` (root), the conventions in `PROJECT_CONTEXT.md`, and the controls documented in `docs/audit/`.

It does NOT replace:

- The built-in `/security-review` slash command (generic vulnerabilities)
- CodeQL / Semgrep / Trivy in CI (SAST + container scans)
- Cloudflare WAF at edge (runtime)
- Manual review of payment, tax, and PII code (still required for every PR)

It adds: **opinionated, project-specific checks** that catch the failure modes specific to a payment-handling AU marketplace.

---

## When to invoke

**Auto-invoke when Claude touches any of these paths:**

| Path                                   | Why                                           |
| -------------------------------------- | --------------------------------------------- |
| `apps/api/src/modules/auth/**`         | Authentication / refresh / OTP                |
| `apps/api/src/modules/payment/**`      | Stripe payments + payment intents             |
| `apps/api/src/modules/payout/**`       | Stripe Connect payouts                        |
| `apps/api/src/modules/tax/**`          | GST + RCTI + ATO reporting                    |
| `apps/api/src/modules/kyc/**`          | Didit KYC integration                         |
| `apps/api/src/modules/ai/**`           | LLM calls + PII redaction                     |
| `apps/api/src/modules/notification/**` | SMS + email (Notifyre)                        |
| `apps/api/src/**/*.controller.ts`      | Any new or modified controller                |
| `apps/api/src/**/webhook*.ts`          | Webhook handlers (Stripe, Didit, Notifyre)    |
| `packages/prisma/schema.prisma`        | Schema changes                                |
| `packages/prisma/migrations/**`        | Migrations                                    |
| `**/.env*` (except `.env.example`)     | Env / secret config                           |
| `apps/api/src/common/guards/**`        | AuthN / AuthZ guards                          |
| `apps/api/src/common/interceptors/**`  | Idempotency / audit / rate-limit interceptors |

**Manual invocation:** `/skill security-review` on any PR or branch.

---

## Output format

The skill produces a structured report:

```
## Security Review — <branch> @ <commit>

Files reviewed: N
Checks run: M
Status: ✅ PASS  /  ⚠️ WARN  /  ❌ FAIL

### Findings

❌ CRITICAL — <category> — <file:line>
   <issue>
   Fix: <suggested change>

⚠️ HIGH — <category> — <file:line>
   <issue>
   Fix: <suggested change>

ℹ️ INFO — <category> — <file:line>
   <note>

### Stage coverage

- Pre-commit:  ✅ enforced by lefthook
- Code:        ✅ N checks passed, M flagged
- App layer:   ✅ N checks passed
- Data layer:  ✅ N checks passed
- Compliance:  ✅ N checks passed

### Sign-off required

[ ] All CRITICAL resolved
[ ] All HIGH resolved or explicitly accepted with comment
[ ] Manual review by human on: payment, tax, PII (per CLAUDE.md rule 2)
```

A PR cannot merge if any CRITICAL is open, or if HIGHs lack written justification.

---

## The checklist

Checks are grouped by category. Each check has: id, severity, what to verify, how to verify, how to fix.

### A. Input validation

**A1 — CRITICAL — DTO present and validated on every endpoint**

- Verify: every `@Body()`, `@Query()`, `@Param()` has a class-validator DTO or Zod schema
- Verify: no `body: any` or `body: object` in controllers
- Verify: `ValidationPipe` is registered globally or per-route
- Fix: add a DTO with `@IsString()` / `@IsInt()` / `@IsEmail()` / etc.

**A2 — HIGH — file uploads are size + MIME-restricted**

- Verify: multer / NestJS file interceptors set `limits.fileSize` and `fileFilter`
- Fix: cap at 10 MB for images, validate `image/*` MIME only

**A3 — HIGH — IDs in URLs are cuid2-shaped**

- Verify: route params named `id` go through `@IsCuid2()` (or regex `^[a-z0-9]{24}$`)
- Fix: add the validation decorator; reject early before DB query

### B. Authentication & authorization

**B1 — CRITICAL — every non-public endpoint has `@UseGuards(JwtAuthGuard)`**

- Verify: no controller method without an auth guard unless explicitly `@Public()`
- Fix: add the guard; add `@Public()` only with reviewer sign-off

**B2 — CRITICAL — every mutating endpoint has role check**

- Verify: `POST`/`PUT`/`PATCH`/`DELETE` routes have `@Roles(Role.POSTER | Role.TASKER | Role.ADMIN)` matching intent
- Fix: add `@Roles(...)` + `RolesGuard`

**B3 — CRITICAL — resource ownership check on `/me/*` and `/users/:id/*` patterns**

- Verify: handler compares `req.user.id` to the resource owner before any mutation/read
- Common bug: `findById(id)` without checking ownership → IDOR
- Fix: query with `where: { id, userId: req.user.id }` or call `assertOwnership(resource, req.user)`

**B4 — HIGH — refresh-token rotation invalidates old token**

- Verify: refresh flow writes `revokedAt` on old token before issuing new one
- Fix: wrap in a Prisma transaction; revoke then issue

**B5 — HIGH — sessions don't outlive password change / KYC revoke**

- Verify: password change calls `revokeAllSessionsForUser(userId)`
- Fix: add the call; emit audit event

### C. Idempotency

**C1 — CRITICAL — every mutating endpoint requires `Idempotency-Key` header**

- Verify: `POST`/`PUT`/`PATCH`/`DELETE` routes go through `IdempotencyInterceptor`
- Verify: interceptor reads `Idempotency-Key`, returns cached response on replay (24h TTL Redis)
- Verify: `GET` is NOT idempotency-checked (safe by definition)
- Fix: register interceptor globally or via `@UseInterceptors(IdempotencyInterceptor)`

**C2 — HIGH — payment + payout flows use Stripe-side idempotency keys**

- Verify: every Stripe API call passes `{ idempotencyKey }` derived from our internal `Idempotency-Key` header (don't reuse — namespace it: `stripe:${ourKey}`)
- Fix: pass the key; never call Stripe without one for mutations

### D. Rate limiting

**D1 — CRITICAL — `/auth/*` endpoints have explicit rate limit**

- Verify: `@RateLimit({ points: 5, duration: 60 })` on login, OTP request, password reset
- Fix: add the decorator; tune per endpoint

**D2 — HIGH — `/payment/*` endpoints rate-limited to 60/min per user**

- Verify: `@RateLimit({ points: 60, duration: 60, keyBy: 'userId' })`
- Fix: add the decorator

**D3 — HIGH — `/ai/*` endpoints rate-limited per user (token+cost protection)**

- Verify: `@RateLimit({ points: 60, duration: 60, keyBy: 'userId' })`
- Fix: add decorator; check `dailyCostUsd <= MAX` before LLM call (cost-cap layer)

### E. SQL & data access

**E1 — CRITICAL — no `$queryRaw`/`$executeRaw` with string interpolation**

- Verify: any `$queryRaw` uses template literals with `Prisma.sql` or parameterized inputs
- Verify: no `` `SELECT * FROM users WHERE id = ${id}` `` style
- Fix: use `Prisma.sql` template or refactor to typed Prisma client

**E2 — CRITICAL — soft-delete filter applied**

- Verify: every Prisma query for soft-deletable models includes `where: { deletedAt: null }` OR uses our `softDeleteExtension`
- Fix: import + apply the extension; or add `deletedAt: null` to the where clause

**E3 — HIGH — pgvector cosine queries use parameter binding**

- Verify: vector search uses `Prisma.sql` template, vector cast `::vector` applied to parameter not concatenation
- Fix: see `.claude/skills/pgvector-match/SKILL.md` reference query

**E4 — HIGH — `select` clauses don't leak fields**

- Verify: when returning user data, no `password*`, `*Hash`, `*Secret`, `refreshToken*`, `embedding` (1536 floats = noise)
- Fix: use explicit `select: {...}` or define a Prisma `omit` extension

### F. PII handling

**F1 — CRITICAL — PII redacted before external LLM calls**

- Verify: every call to Gemini/Claude/OpenAI goes through `apps/api/src/modules/ai/pii.ts`'s `redactPii()` wrapper
- Verify: no raw `messages: [{ content: userInput }]` patterns
- Fix: wrap with `await callLlm(redactPii(prompt))`

**F2 — CRITICAL — no PII in application logs**

- Verify: log statements don't include email, phone, full name, address, ID document number, ABN, bank details
- Verify: use `[REDACTED:email]` placeholders or `pino.redact` config
- Fix: configure pino redact list; review the log line

**F3 — HIGH — PII in error responses limited**

- Verify: 4xx error bodies don't include other users' PII
- Verify: exception filter sanitizes before serializing
- Fix: update global exception filter

**F4 — HIGH — KYC payload minimization (Didit)**

- Verify: we store only `diditSessionId`, `kycStatus`, `kycVerifiedAt`, `documentType` (NOT number)
- Verify: we never persist ID document images, selfies, or government ID numbers
- Fix: remove the column / null the field; document in `docs/audit/data-retention.md`

**F5 — HIGH — DSR (Privacy Act) endpoints exist and tested**

- Verify: `/me/export` (download all PII) and `/me/delete` (anonymise) are implemented
- Fix: build per `PROJECT_CONTEXT.md` §8

### G. Secrets

**G1 — CRITICAL — no hardcoded secrets in source**

- Verify: gitleaks pre-commit blocks; CI scan green
- Verify: no `apiKey: 'sk_...'` patterns
- Fix: move to `.env.local` (dev) or Key Vault (staging/prod)

**G2 — CRITICAL — `.env.example` has no real values**

- Verify: only placeholders like `STRIPE_SECRET_KEY=sk_test_...`
- Fix: replace with placeholder; rotate any leaked key immediately

**G3 — HIGH — secrets loaded from Key Vault in staging/prod**

- Verify: `ConfigService` reads from Key Vault references (`@Microsoft.KeyVault(...)`) in non-dev environments
- Fix: update App Service config to use Key Vault references

### H. Money & financial integrity

**H1 — CRITICAL — all money fields are `Int` (cents)**

- Verify: Prisma schema: no `Decimal`, `Float`, `Money` for amounts
- Verify: TS code: `number` representing cents (never dollars-as-decimal)
- Fix: refactor to `Int` cents; update consumers

**H2 — CRITICAL — currency code stored alongside amount**

- Verify: every money-bearing row has `currency` field (default `AUD`)
- Fix: add the column; backfill `AUD`

**H3 — CRITICAL — GST calculation goes through `apps/api/src/modules/tax/gst.service.ts`**

- Verify: no inline `* 0.1` or `* 1.1` math
- Fix: call the service; it handles rounding + edge cases

**H4 — HIGH — RCTI generation triggered on payout, not on bid acceptance**

- Verify: state machine `Bid.accepted → Task.completed → Payment.captured → Payout.released → RCTI.issued`
- Fix: refactor trigger location; reference `.claude/skills/au-tax/SKILL.md`

**H5 — CRITICAL — webhook signature verification before processing**

- Verify: Stripe webhooks call `stripe.webhooks.constructEvent()` with raw body + signature
- Verify: Didit webhooks verify HMAC signature
- Verify: Notifyre webhooks (if any) verify per their docs
- Fix: never trust webhook payload without signature; respond 400 on fail

### I. Audit trail

**I1 — CRITICAL — money / role / KYC changes write to `AuditLog`**

- Verify: payment capture, refund, payout, role grant/revoke, KYC status change all emit `auditLog.create({ ... })`
- Verify: log includes `actorId`, `action`, `targetType`, `targetId`, `before`, `after`, `at`
- Fix: add the write; use a NestJS interceptor for consistent shape

**I2 — HIGH — audit log is append-only**

- Verify: no `auditLog.update()` or `auditLog.delete()` anywhere in code
- Verify: Prisma has no relation that cascades into AuditLog deletion
- Fix: remove offending code; consider DB-level revoke on UPDATE/DELETE for the table

### J. External LLM cost & abuse protection

**J1 — HIGH — every LLM call has a model + cost ceiling**

- Verify: `callLlm()` wrapper checks `dailyUserCostUsd` and `dailyGlobalCostUsd` before calling
- Verify: vision calls use Flash tier first, Pro only on fallback (per multimodal-extraction skill)
- Fix: wire in cost guard middleware

**J2 — HIGH — prompt-injection defenses on user-supplied text**

- Verify: user-supplied text in prompts is wrapped in delimiters + instruction reminders, OR uses structured tool-call format
- Fix: use the project's `wrapUserText()` helper

### K. Compliance hooks (AU-specific)

**K1 — CRITICAL — countryCode always defaults to `AU` at MVP**

- Verify: every multi-country branch has an AU default
- Fix: add `?? 'AU'` fallback

**K2 — HIGH — ABN validation when collected**

- Verify: ABNs go through `validateAbn()` (checksum) before storage
- Fix: add the validator

**K3 — HIGH — sharing-economy reporting fields populated**

- Verify: tasker rows have name, ABN (or `noAbnReason`), address, and we record `totalEarningsCentsByPeriod`
- Fix: per `.claude/skills/au-tax/SKILL.md`

### L. Test coverage for sensitive routes

**L1 — HIGH — sensitive route has 3 minimum tests**

- Verify: for every route under auth/payment/payout/tax/kyc/ai, tests exist for:
  - happy path
  - unauthenticated request (expect 401)
  - unauthorized role (expect 403)
  - ownership violation where applicable (expect 403)
  - replay with same idempotency key (expect cached response, not duplicate effect)
- Fix: add missing tests

**L2 — HIGH — webhook handler has signature-fail test**

- Verify: test case for invalid signature → 400 + no DB side effect
- Fix: add the test

### M. Documentation hooks

**M1 — INFO — ADR exists for new pattern**

- Verify: if change introduces a new architectural pattern, `docs/adrs/NNN-*.md` exists
- Fix: write the ADR before merging

**M2 — INFO — audit doc updated if control changes**

- Verify: if change affects a documented control, `docs/audit/*.md` is updated in the same PR
- Fix: update the doc

---

## Stage coverage map

| Stage                            | Mechanism                                                               | Skill role                                              |
| -------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------- |
| **Pre-commit (local)**           | lefthook + gitleaks + ESLint + prettier + tsc                           | Skill runs here when AI is editing; flags before commit |
| **Code review (Claude editing)** | This skill, triggered by file patterns above                            | Primary defensive layer for AI-authored code            |
| **PR / CI**                      | GitHub Actions: lint, test, typecheck, CodeQL, Semgrep, Trivy (planned) | Skill report can be appended to PR description          |
| **Merge gate**                   | Branch protection: CI green + 1 reviewer + no CRITICAL findings         | Skill report attached for reviewer                      |
| **Deploy**                       | Terraform plan review, manual approval                                  | N/A                                                     |
| **Runtime**                      | Cloudflare WAF + rate limits + audit log + App Insights alerts          | N/A                                                     |

---

## How to run

When a triggering file is touched, Claude should:

1. Identify which checks in the list above apply to the changed files
2. For each applicable check, examine the actual code and verify the rule
3. Produce the structured report in the **Output format** section
4. If any CRITICAL is open: refuse to mark the work complete; tell the user what must be fixed
5. If only HIGH or INFO: surface them with suggested fixes, ask user for sign-off

Manual invocation: `/skill security-review` runs the full checklist against the current branch's diff vs `main`.

---

## Escalation

Escalate to **human review required** (do not auto-fix) when:

- Any change to `apps/api/src/modules/payment/**` or `payout/**` → human reviews every line
- Any change to `apps/api/src/modules/tax/**` → engage tax advisor per `CLAUDE.md` rule 4
- Any change to `packages/prisma/schema.prisma` involving money or PII columns
- Any new external vendor SDK added
- Any new webhook endpoint
- Any change to PII redaction logic in `apps/api/src/modules/ai/pii.ts`

These are the **biggest blast-radius** areas. Skill flags; human signs off.

---

## What this skill is NOT

- ❌ Not a substitute for SAST (CodeQL/Semgrep handle that better — different failure modes)
- ❌ Not a substitute for dependency scanning (Trivy + Dependabot handle that)
- ❌ Not a substitute for runtime defenses (WAF, rate limits, App Insights anomaly alerts)
- ❌ Not a substitute for a third-party pen test before production launch
- ❌ Not a substitute for human review of payment, tax, and PII code (still required per CLAUDE.md)

It IS: a project-specific, opinionated, AI-assistant-level gate that knows the JOBBees rules the way a senior engineer who's been on the team for 6 months would know them.

---

## References

- `CLAUDE.md` — root rules (hard non-negotiables)
- `PROJECT_CONTEXT.md` — full architecture + compliance
- `docs/audit/edge-security.md` — WAF + DDoS layer
- `docs/audit/encryption-policy.md` — TLS + KMS
- `docs/audit/incident-response-plan.md` — what to do when something bad happens
- `.claude/skills/stripe-payment/SKILL.md` — payment state machine
- `.claude/skills/au-tax/SKILL.md` — GST + RCTI + ATO
- `.claude/skills/pgvector-match/SKILL.md` — vector queries
- `.claude/skills/tier0-dispute/SKILL.md` — dispute mediator
- `.claude/skills/multimodal-extraction/SKILL.md` — vision extraction
