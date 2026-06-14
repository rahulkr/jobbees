# Sprint 1 — Backend Auth Foundation

> **Note:** Filename kept as `sprint-01-onboarding-and-auth.md` for git history continuity, but per the 2026-06-12 plan restructure, Sprint 1 is now **backend-only**. Mobile onboarding + auth screens move to Sprint 2 (where they're built against the now-stable backend). See `PLAN.md` operating principle #1 for the rationale.

**Dates:** Mon 22 Jun → Fri 3 Jul 2026 (10 working days)
**Theme:** Build the auth API + shared backend infra solid enough that mobile (starting Sprint 2) integrates against a real, secure, tested surface. No mobile code in this sprint.
**Hours budget:** ~80 (75 backend, 5 admin gate)
**Mid-sprint demo:** Fri 26 Jun
**End-of-sprint demo:** Fri 3 Jul

## Goal in one sentence

By Friday 3 Jul, every auth flow the mobile app will need in Sprint 2 — email/Google/Apple signup, login, OTP verify (against MockOtpService), refresh, logout (with server-side session revoke), `/me`, RBAC role grants — works end-to-end via Postman/Swagger against local Postgres + Redis, with AuditLog rows for every state transition and integration tests covering happy + auth + idempotency + signature-fail paths.

## Why backend-first (the deliberate trade-off)

Originally Sprint 1 was mobile-heavy onboarding (welcome carousel, signup forms, OTP UI, biometric). For a solo dev that forces building mobile against a non-existent backend, then refactoring once the backend lands. Backend-first means:

1. The auth API is the riskiest foundational piece — getting it nailed before any UI code reduces rework
2. Mobile sprints integrate against a real API, not mocks
3. Sprint 1 demo is technical (Postman + Swagger + DB queries) — the client sees infrastructure, not UI
4. From Sprint 2 onwards every Friday is "click through the app"

**What we accept:** no mobile UI to demo on Fri 3 Jul. Frame the demo as "the foundation that saves three weeks of mobile rework later." Use the second hour of the demo to walk through Figma mockups for the Sprint 2 mobile work.

## Scope — inventory rows in this sprint

### Backend (apps/api) — almost the whole sprint

| ID  | Item                                                                                                                                                                                                                  | Call | Hrs | Notes                                                                                        |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---- | --- | -------------------------------------------------------------------------------------------- |
| —   | NestJS app scaffold (app module, config, pino logger, global exception filter, OpenAPI/Swagger setup)                                                                                                                 | IN   | 4   | Shared infra; reused by every subsequent sprint                                              |
| —   | Shared infra: idempotency interceptor (Redis-backed, 24h TTL), per-route rate-limit guard, error mapper, request-ID middleware                                                                                        | IN   | 6   | Shared infra; reused by every subsequent sprint                                              |
| 228 | User CRUD endpoints                                                                                                                                                                                                   | IN   | 6   |                                                                                              |
| 229 | OAuth providers (Google, Apple) — server-side ID-token verification + user upsert                                                                                                                                     | IN   | 6   | Token validation, profile merge, account-linking rules                                       |
| 230 | JWT session (15min access / 30d refresh) + refresh rotation with `revokedAt` write                                                                                                                                    | IN   | 5   | Transactional revoke-then-issue                                                              |
| 231 | Password hashing (argon2id) + reset tokens                                                                                                                                                                            | IN   | 2   | Per CLAUDE.md security rule (argon2id only)                                                  |
| 232 | OTP service — `OtpService` interface + `MockOtpService` impl (dev). 3 safety guards per ADR 008: startup assertion (`NODE_ENV !== 'production'`), Semgrep rule blocking commits, AuditLog write on every mock-OTP use | IN   | 5   | Mock accepts `000000` for any phone. Real provider swap in Sprint 5                          |
| 233 | Email verification flow (mock email link in dev; SendGrid wired in S5)                                                                                                                                                | IN   | 2   |                                                                                              |
| 234 | Phone OTP verification (gated by `userType === 'tasker'` — clients skip this)                                                                                                                                         | IN   | 3   | Uses MockOtpService                                                                          |
| 235 | Biometric token exchange endpoint (mobile presents a server-issued token bound to the device's biometric proof)                                                                                                       | IN   | 2   |                                                                                              |
| 236 | Role-based permissions: `RolesGuard` + `@Roles()` decorator + CLIENT/TASKER/ADMIN enum                                                                                                                                | IN   | 4   |                                                                                              |
| 237 | Account suspension / ban — schema fields + admin-triggered endpoints + session revoke on suspend                                                                                                                      | IN   | 3   |                                                                                              |
| 239 | Session revocation (logout-all-devices) — Redis JWT denylist with key TTL = refresh token TTL                                                                                                                         | THIN | 2   |                                                                                              |
| 242 | User profile API — basic profile only this sprint (skills + service areas come in S2)                                                                                                                                 | IN   | 3   |                                                                                              |
| 245 | Re-auth gate for change-email / change-phone — short-window proof-of-recent-auth                                                                                                                                      | IN   | 3   |                                                                                              |
| 246 | `/me` endpoint + `JwtAuthGuard` + globally applied                                                                                                                                                                    | IN   | 3   |                                                                                              |
| —   | AuditLog interceptor — auto-write on every mutating endpoint per skill §I                                                                                                                                             | IN   | 4   | Shared infra                                                                                 |
| —   | Integration tests covering happy + 401 + 403 + idempotency replay + invalid signature (the L1 + L2 test rules from the security-review skill)                                                                         | IN   | 8   | Every above row gets coverage; bundles the test work that the rest of the project depends on |
| —   | OpenAPI + Swagger doc generation + Postman collection export                                                                                                                                                          | IN   | 3   | The deliverable that proves the API is callable                                              |

**Backend total: ~74h**

### Admin (apps/admin) — gate only

| ID  | Item                            | Call | Hrs | Notes                                                            |
| --- | ------------------------------- | ---- | --- | ---------------------------------------------------------------- |
| 420 | Admin login                     | IN   | 3   | Just the gate — full admin in S9. Uses the same JWT + RBAC infra |
| 424 | Admin session timeout + re-auth | IN   | 2   |                                                                  |

**Admin total: ~5h**

### Mobile (apps/mobile)

**ZERO in this sprint.** Mobile starts in Sprint 2.

The Sprint 1 hours that "would have" gone to mobile (welcome carousel, signup screens, OTP UI, biometric, role select) move to Sprint 2's budget.

### Schema additions (packages/prisma)

Already covered in the existing `User` model. Confirm:

- `User.emailVerified`, `User.phoneVerified` ✅
- `User.role` enum ✅
- `User.passwordHash` ✅ (nullable for social-only)
- `User.deletedAt` ✅
- `User.anonymisedAt` ✅

**New tables added in S1:**

- `RefreshToken` — `id` (cuid2), `userId`, `tokenHash`, `issuedAt`, `expiresAt`, `revokedAt DateTime?`, `replacedById String?` (for rotation chain), `userAgent`, `ipAddress`. Indexes on `userId`, `expiresAt`, `revokedAt`.
- `EmailVerificationToken` — `id`, `userId`, `tokenHash`, `expiresAt`, `usedAt DateTime?`.
- `PasswordResetToken` — same shape as EmailVerificationToken.
- `AuditLog` — already exists; this sprint wires up the interceptor that writes to it.

## Decision gates — already resolved (no Day-1 gate)

All architectural decisions for this sprint are locked from Sprint 0:

- **Auth token storage** — ADR 006 ✅ Bearer for mobile (Keychain/Keystore), HttpOnly cookie + CSRF for web/admin. Per-surface.
- **Refresh token storage** — Postgres (`RefreshToken` model) with Redis denylist for revoked-but-not-expired tokens.
- **OTP service for dev** — MockOtpService per ADR 008, with 3 safety guards.
- **Password hashing** — argon2id (CLAUDE.md rule).

No client-facing decisions block this sprint.

## Definition of done

Every backend row above:

- [ ] Endpoint exists with class-validator DTO (no `body: any`)
- [ ] `@UseGuards(JwtAuthGuard)` + `@Roles(...)` applied per security-review skill §B1/B2
- [ ] Mutating endpoints go through `IdempotencyInterceptor`
- [ ] Auth endpoints have explicit `@RateLimit({ points: 5, duration: 60 })` per skill §D1
- [ ] AuditLog write on every state transition per skill §I1
- [ ] Tests: happy path + 401 + 403 + idempotency replay + (where applicable) ownership IDOR
- [ ] OpenAPI doc generates the endpoint with example request/response

**Sprint-level:**

- [ ] MockOtpService startup assertion fires if `NODE_ENV === 'production'`
- [ ] Semgrep rule `jobbees-mock-otp-in-prod-env` is green
- [ ] CI green on `main` (lint + test + typecheck + Semgrep + gitleaks)
- [ ] `pnpm audit` zero high/critical
- [ ] Postman collection committed to `apps/api/postman/` and pushed
- [ ] Swagger UI accessible at `localhost:3000/api/docs`

## Friday demo (Fri 3 Jul) — "Foundation demo" script

Roughly 5 minutes, technical-client tone:

```
00:00 — "Sprint 1 wrap. Foundation demo. No UI this sprint — but the
        next two weeks of mobile work would have taken three weeks
        without this. Let's see what's there."

00:20 — Open Postman collection. Walk through:
        - POST /auth/signup (email + password) → 201 + tokens
        - GET /me (with token) → user profile
        - POST /auth/refresh (refresh token) → new pair, old one revoked
        - POST /auth/logout → 204 + DB shows session revoked

01:00 — Switch to psql:
        SELECT id, email, role, "createdAt" FROM "User" ORDER BY "createdAt" DESC LIMIT 3;
        SELECT "actorId", action, "targetType", "createdAt" FROM "AuditLog" ORDER BY "createdAt" DESC LIMIT 10;
        — every signup, login, refresh, logout shows up as an AuditLog row

01:30 — Open Swagger UI at localhost:3000/api/docs. Show:
        - Every endpoint documented with example request/response
        - Auth schemes wired up so client devs can self-serve

02:00 — Show MockOtpService:
        - POST /auth/otp/send → returns 200 with no SMS sent
        - Show server log line: "[MOCK OTP] phone=+61400000000 code=000000 — production safeguards: { nodeEnv: 'development', auditLogged: true }"
        - POST /auth/otp/verify with code 000000 → 200 + phoneVerified: true
        - Demonstrate startup assertion: set NODE_ENV=production and start the app — it refuses to boot with a fatal error

02:40 — Show Semgrep + security-review skill output:
        - jobbees-mock-otp-in-prod-env: clean
        - jobbees-stores-government-id-number: clean
        - security-review skill checklist: all CRITICAL passed

03:10 — Show CI:
        - GitHub Actions green on the merge commit
        - Test coverage report
        - gitleaks clean

03:30 — Stoplight:
        ✅ Green: auth, MockOtpService, RBAC, AuditLog, idempotency, rate limits, CI gates
        🟡 Yellow: real OTP provider deferred to S5 (intentional, ADR 008)
        🔴 Red: none

03:50 — "Sprint 2 starts Monday: mobile app starts here. Every screen
        will hit the API you just saw. First user-visible demo on
        Fri 17 Jul."

04:30 — End. Send the Postman collection, Swagger link, and demo
        recording to the client.
```

## What runs in parallel (non-coding work during Sprint 1)

Operational items with lead times:

- **Notifyre `JOBBEES` alpha sender ID** — apply Mon 22 Jun (5-7 business day approval). Needed for Sprint 5 OTP swap + Sprint 8 notifications.

Already in place (no action needed):

- ✅ Stripe account exists — Connect Express integration uses existing account
- ✅ Apple Developer Program — enrolled
- ✅ Google Developer / Play Console — enrolled

Deferred to later sprints:

- **Lawyer engagement for ToS + Privacy Policy** — deferred to Sprint 11. Strategy: during Sprint 8 (Notifications + Trust + Privacy), draft Privacy Policy + ToS yourself from a public template (Airtasker / hipages style). Lawyer in Sprint 11 reviews + customizes instead of drafting from scratch. **Hard deadline:** must be published before flipping Stripe to live mode in Sprint 12.
- **Tax advisor RFP** — soft-engage by mid-Sprint 5 (identify + shortlist, no money committed). Formal paid review in Sprint 11 before Sprint 12 launch. Rationale: Sprint 6 lands GST + RCTI + ATO code which is the highest AI-hallucination-risk area per CLAUDE.md rule 4. Having an advisor lined up means you can ask a quick "is this RCTI logic right?" question when needed.

Skip:

- ~~Figma mockups for Sprint 2 mobile screens~~ — not doing. Direct to Flutter using `docs/brand/` theme tokens.

## Risks specific to Sprint 1

| Risk                                                            | Likelihood | Impact   | Mitigation                                                                                                                                                                     |
| --------------------------------------------------------------- | ---------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Client gets nervous about no-UI Sprint 1                        | Medium     | Medium   | Frame upfront: "Foundation demo, then Sprint 2 first click-through." Show Figma mockups in same call. Mid-sprint Friday sync (Fri 26 Jun) shows Postman calls already working. |
| MockOtpService 3-guard pattern hard to implement                | Low        | High     | All 3 layers documented in ADR 008 with code samples; Semgrep rule already written; the only fresh code is the runtime assertion (5 lines) + the AuditLog write (10 lines)     |
| Refresh-token rotation race condition                           | Low        | Critical | Wrap revoke + issue in a single Prisma transaction. Integration test asserts old token returns 401 immediately after refresh. Per skill §B4.                                   |
| Social-auth (Google + Apple) ID token verification subtle bugs  | Medium     | High     | Use official `google-auth-library` + `jose` for Apple JWKS verification. Don't roll our own. Tests cover invalid signature, expired token, mismatched audience                 |
| Notifyre `JOBBEES` alpha sender ID approval slips past Sprint 5 | Low        | Medium   | Apply Mon 22 Jun (5-7 business day target); follow up if no answer by Wed 1 Jul. If late, Sprint 5 OTP swap can ship with default sender ID and rebrand later                  |

## End-of-sprint checklist (Fri 3 Jul afternoon)

1. Update `inventory/JOBBees_Feature_Inventory.csv` column 9 for every backend row → `done [sprint-1, PR#nn]`
2. Run `./scripts/coverage.sh > /tmp/coverage-s1.txt`
3. Run `./scripts/coverage.sh --by-section > /tmp/coverage-s1-by-section.txt`
4. Email client: foundation demo video link + Postman collection + Swagger URL + Figma mockup link + Sprint 2 demo script preview
5. Commit `docs/sprints/sprint-02-kyc-tasker-connect.md` if any updates needed (it's already detailed)
6. Tag merge commit on `main` as `sprint-01-end`
7. Close the sprint in tracker
8. Two-day weekend. Don't open the laptop. Sprint 2 starts Mon 6 Jul.
