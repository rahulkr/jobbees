<!--
JOBBees PR template.
Keep PRs small (< 400 LOC changed). One feature per branch. Conventional Commits in title.
-->

## What & why

<!-- 1–3 sentences. What does this PR do, and why is it needed? -->

## Linked work item

<!-- Ticket / issue / inventory row this PR closes. -->

- Closes: #

## How to verify

<!-- Steps a reviewer can run locally to see this working. -->

```
# example
pnpm dev
# then hit POST /api/...
```

---

## Reviewer checklist

Walk through every box that applies. Tick **only** what you've actually verified.

### Always

- [ ] PR title follows Conventional Commits (`feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`)
- [ ] One feature / fix per PR (no drive-by refactors mixed in)
- [ ] CI is green (lint, test, typecheck, gitleaks, Semgrep)
- [ ] No CRITICAL findings from the `security-review` Claude skill (or written justification below)
- [ ] No new `// TODO` / `// FIXME` without a linked ticket
- [ ] Diff is < 400 lines OR explicitly justified

### Touches `apps/api/src/modules/auth/**`?

- [ ] N/A
- [ ] Endpoint has `@UseGuards(JwtAuthGuard)` or is explicitly `@Public()`
- [ ] Mutating endpoint has explicit `@RateLimit(...)` (5/min on login/OTP/reset)
- [ ] Refresh-token rotation revokes the old token in a transaction
- [ ] Password change / KYC revoke calls `revokeAllSessionsForUser(...)`
- [ ] Auth-failure test exists for the new/changed route

### Touches `apps/api/src/modules/payment/**` or `payout/**`?

- [ ] N/A
- [ ] **Reviewed every line by hand** (CLAUDE.md rule 2 — not just CI-skimmed)
- [ ] All money fields are `Int` (cents) — no `Decimal`, no `Float`
- [ ] Currency field present and defaults to `AUD`
- [ ] Every Stripe mutating call has `{ idempotencyKey: ... }`
- [ ] `Idempotency-Key` header enforced via `IdempotencyInterceptor`
- [ ] Webhook handler verifies signature via `stripe.webhooks.constructEvent(...)` before processing
- [ ] State machine transitions are explicit and audited
- [ ] AuditLog write on capture / refund / payout / cancel
- [ ] Tests cover: happy path, replay with same idempotency key, signature failure (webhook)

### Touches `apps/api/src/modules/tax/**`?

- [ ] N/A
- [ ] **Reviewed every line by hand** (CLAUDE.md rule 4)
- [ ] No inline GST math — all calculation goes through `gst.service.ts`
- [ ] RCTI triggered on payout (not on offer accept)
- [ ] ABN validated via `validateAbn(...)` before storage
- [ ] Sharing-economy reporting fields populated (name, ABN or `noAbnReason`, address)
- [ ] Tax-advisor review required if this changes RCTI / ATO logic — flagged in PR description

### Touches `apps/api/src/modules/license/**` (per-category trade license verification)?

Per **ADR 005**: no identity-vendor KYC. Verification = Stripe Connect (Stripe handles) + ABN (ABR API) + License (manual admin review).

- [ ] N/A
- [ ] Offer-time guard: tasker without APPROVED + non-expired License for a `requiresLicense: true` Category cannot make an offer (403 with actionable message)
- [ ] License expiry cron: APPROVED licenses with `expiresAt < now()` auto-transition to EXPIRED + email tasker; 14d/7d/1d advance reminders fire
- [ ] License blobs stored under retention policy in `docs/audit/data-retention-policy.md` (7 years)
- [ ] AuditLog write on every License status transition (PENDING → APPROVED / REJECTED / EXPIRED), with admin `actorId` for manual decisions
- [ ] Admin license review queue cross-checks against AU state register URL (recorded in reviewer notes)
- [ ] No license number persisted from a state register other than the one the tasker claimed (i.e., don't accidentally cross-check VIC registers for a NSW-issued license without recording it)

### Touches `apps/mobile/lib/features/**/screens/**` (any Flutter screen — creating OR editing)?

Per `docs/brand/DESIGN-QUALITY-CHARTER.md`. Every screen must pass the 12 rejection criteria AND the design gate below. No exceptions without a one-line written justification per unchecked box.

**This applies to editing existing screens too.** If the touched screen is listed as **Tier B** in `docs/brand/design-debt.md`, the retrofit must happen in this same PR before merge. Update the tracker status in the same PR.

- [ ] N/A
- [ ] Screen category identified + reference bar named (from the charter's screen-personality table)
- [ ] No default Material widgets on screen (only `J*` components or composed custom layouts)
- [ ] Coral appears ≤ 2 times on screen; one dominant CTA
- [ ] Featured / regular / state variants are visually distinct (not just labelled)
- [ ] Entrance animation defined (not default page-push)
- [ ] Interactive elements have press response (haptic + scale/opacity)
- [ ] Skeleton state built (or spinner justified — button/inline/streaming context only)
- [ ] Empty state built with Lucide icon + microcopy voice
- [ ] Error state built with named-problem title + retry
- [ ] Long-text overflow tested (40+ char titles, 300+ char bodies)
- [ ] Keyboard-up state tested (all inputs)
- [ ] Light + dark mode both feel intentional (not one design × 2 palettes)
- [ ] Widgetbook composed page exists at `widgetbook/screens/<category>/<name>_page.dart` (Widgetbook lock — built _before_ screen implementation)
- [ ] Screenshots in both modes attached to PR

### Touches `apps/api/src/modules/ai/**` or any external LLM call?

- [ ] N/A
- [ ] All user-supplied text passes through `redactPii(...)` from `pii.ts`
- [ ] Vision calls use Gemini Flash tier first; Pro only on explicit fallback
- [ ] Cost guard (`dailyUserCostUsd` + `dailyGlobalCostUsd`) checked before call
- [ ] Per-user rate limit applied (`@RateLimit({ keyBy: 'userId' })`)
- [ ] Prompt-injection defenses applied to user-supplied text

### Touches `packages/prisma/schema.prisma` or `migrations/**`?

- [ ] N/A
- [ ] IDs are `cuid2` strings (not `cuid()` cuid1, not `autoincrement()`)
- [ ] FK fields have matching `@@index([fieldId])`
- [ ] Money fields use `Int` cents + nearby `currency` field
- [ ] Soft-delete (`deletedAt DateTime?`) on user-facing entities
- [ ] Migration tested against current dev DB (`pnpm db:migrate:dev`)
- [ ] No down-migration data loss for existing rows
- [ ] ADR exists if this introduces a new pattern (under `docs/adrs/`)

### Touches webhook endpoints?

- [ ] N/A
- [ ] Raw body preserved for signature verification (no body-parser overwriting)
- [ ] Signature verified before any DB write or external call
- [ ] Returns 400 on signature failure (not 200 + silent ignore)
- [ ] Idempotency: replays of the same provider event ID are no-ops
- [ ] Test case for invalid signature exists

### Touches `.env*` or config?

- [ ] N/A
- [ ] `.env.example` updated with placeholder for any new variable
- [ ] No real secrets in `.env.example`
- [ ] Real values read via `ConfigService` (not direct `process.env.X`)
- [ ] Key Vault reference syntax used for staging/prod values
- [ ] Documented in `PROJECT_CONTEXT.md` if it's a new integration

### Touches edge / infra (`ops/terraform/**`, `ops/docker/**`)?

- [ ] N/A
- [ ] Terraform plan reviewed before apply
- [ ] No public IP exposure on Postgres / Redis / Blob / Key Vault
- [ ] Resource tags include `env`, `owner`, `costCenter`
- [ ] Cost-impacting change called out in PR description

### Touches docs?

- [ ] N/A
- [ ] `PROJECT_CONTEXT.md` updated if architecture / convention changed
- [ ] ADR added under `docs/adrs/NNN-*.md` if a new decision was made
- [ ] `docs/audit/*.md` updated if a documented control changed
- [ ] CLAUDE.md (root or app-level) updated if conventions changed

---

## CRITICAL / HIGH security findings — justification

<!--
Paste any open CRITICAL or HIGH findings from the security-review skill or Semgrep
that you are explicitly accepting. Each entry: rule id, file:line, WHY it's safe.
Leave blank if none.
-->

```
none
```

## Notes for reviewer

<!-- Anything the reviewer should know up front. Tricky bits, deferred work, follow-ups. -->

---

<sub>Reviewer: read `CLAUDE.md` (root) before reviewing if you haven't recently. PRs touching payment, tax, or PII require human line-by-line review — not just CI sign-off.</sub>
