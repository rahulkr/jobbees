# JOBBees — MVP Sprint Plan

**Project kick-off:** Mon 1 Jun 2026
**Cadence:** 2-week sprints (Sprint 0 is 3 weeks — extended foundation)
**Sprint 0 (setup):** Mon 1 Jun → Fri 19 Jun 2026 (extended by 1 week to absorb research catch-up — AI skills generation, ADRs 005-008, license verification design, brand lock-in)
**Sprint 1 (first build sprint):** Mon 22 Jun 2026
**Sprint 12 (final):** Fri 8 Jan 2027 (was Fri 4 Dec 2026; pushed by ~5 weeks per 14 Jun founder re-scope of Flutter Web + Next.js SEO into MVP)
**Total delivery: 13 sprints** = 1 setup (3 weeks) + 12 production build sprints (mostly 2 weeks each; Sprints 3 and 11 grow to 3 weeks to absorb the web + SEO work) = ~32 weeks
**Demo cadence:** End-of-sprint Friday afternoon, weekly mid-sprint Friday optional sync
**Tracker:** `inventory/JOBBees_Feature_Inventory.csv` (gitignored) updated each Friday
**Coverage script:** `./scripts/coverage.sh` (run before client call)
**Post-MVP appendix:** [`docs/sprints/post-mvp-deferred.md`](./post-mvp-deferred.md) — single source of truth for every consciously deferred item.
**Scope reconciliation:** Saiju's Scope Reconciliation review (Jun 2026) compared Estimation v1.2 (394 in-scope items) against this plan and the Master Test Plan v2.0 (481 TCs). 28 gaps surfaced; resolutions:

- 12 reinstated into named sprints (S1, S2, S3, S5, S8, S9, S11 — see each sprint doc for "scope reconciliation" rows)
- 7 deferred to V2 — see [`post-mvp-deferred.md`](./post-mvp-deferred.md)
- 6 confirmed already in scope (pen test, KYC via Stripe Connect, single admin role, per-class retention durations, 4-role enum, Cloudflare WAF) — see [`post-mvp-deferred.md`](./post-mvp-deferred.md) bottom section.

**14 June 2026 founder re-scope:** Flutter Web app (18 items) + Next.js public SEO site (18 items) + AI auto-SEO content generation (1 item) pulled IN from the V2 appendix back into MVP. Foundation in S1; Web parity rows in each of S2-S8 mirroring mobile screens; full SEO bundle in S11 (with SEO phase 1 — public job pages — in S3). Adds ~162h of net new work. Sprint 3 grows from 2 weeks → 3 weeks (Mon 20 Jul → Fri 7 Aug); Sprint 11 grows from 2 weeks → 3 weeks (Mon 23 Nov → Fri 11 Dec). Soft launch shifts from Fri 4 Dec 2026 → **Fri 8 Jan 2027**. Same sprint cadence preserved across the rest of the calendar.

**14 June 2026 Estimation v1.2 direct verification:** after a full row-by-row check against Estimation v1.2 (474 features, 398 in-scope, 1,420 raw hours), 4 items previously deferred to V2 were re-scoped back into MVP, and 17 items genuinely missing from sprint docs were added. Total ~136h of additional work absorbed into existing sprints; same calendar (soft launch still Fri 8 Jan 2027). Pulled back from V2: behavioural fraud scoring B-48 (S7), device fingerprinting M-229 (S8), two-person approval AP-56 (S9), RAG support agent #194 (S8). Newly added: M-228 AI Welcome Agent (S2), M-230 versioned consent capture (S8), M-231 account lockout (S1), M-233 income statement mobile (S6), M-234 supply soft-block + waitlist (S3), B-44b PII blur on photos (S3), B-54 TFN encryption (S6), B-55 income statement batch job (S6), B-56 payment lifecycle edge cases (S5), B-57 auto-suspend rules engine (S7), AP-09b create user from admin (S9), AP-47b FSE Admin Role (S9), AP-57 ATO SERR export (S9), AP-58 reinstatement workflow (S9), AP-59 promo code admin (S9), AI-01 LLM router (S3), DEV-09 Terraform IaC (S10), DEV-12 Sentry PII scrubbing (S2), DEV-13 CMK (S10).

## Sprint 0 vs Sprints 1-12

Sprint 0 is the **foundation sprint** — it isn't part of the 12-sprint build budget. It covers everything that has to be in place before feature work starts: monorepo scaffold, schema, ADRs (005-008), IT audit documentation, custom AI tooling, security gates, CI, repo on GitHub, plan + coverage tracker, brand theme lock-in, license verification model design. It's been running since Mon 1 Jun and wraps Fri 19 Jun (extended by one week to absorb the research catch-up: AI skills generation, license verification design, ADR cycles, brand colour lock-in from the RN prototype).

Sprints 1-12 are the **feature build budget** — these consume the ~945-hour estimate from v1.1.

The client gets a Sprint 0 wrap demo on Fri 19 Jun showing: repo layout, plan, security gates, ADRs, audit docs. That demo confirms the locked decisions (verification model — ADR 005, auth-token storage — ADR 006, edge security — ADR 007, OTP pattern — ADR 008) and surfaces only the operational items still in flight (OAuth client IDs, Notifyre alpha sender application).

## Operating principles

1. **Vertical slices, not horizontal layers — with one deliberate exception (Sprint 1).** From Sprint 2 onwards, every sprint produces something the client can click through on the mobile app or admin console. Sprint 1 is intentionally backend-only — the auth foundation. We accept a "technical demo" (Postman + Swagger + DB queries) for Sprint 1 in exchange for never building mobile against an unstable API. From Sprint 2 onward, no more invisible-backend sprints.
2. **Local-first dev, infra last.** No Azure spend until Sprint 10. Local Postgres + Redis (Docker), local NestJS dev server, ngrok for Stripe webhooks.
3. **Weekly Friday demo, biweekly Friday wrap.** Mid-sprint Friday = quick "here's what's working so far" video. End-of-sprint Friday = full demo + scope close-out.
4. **Zero tolerance for feature loss.** Every IN / IN★ row in the inventory CSV gets marked `done [sprint-N, PR#nn]` as it lands. The coverage script reads the CSV and reports the percentage; you can never accidentally skip a feature.
5. **Compliance gates are non-negotiable.** Payment, tax, KYC, and PII changes require human line-by-line review (CLAUDE.md rule 2). The `security-review` skill auto-runs on these paths.
6. **Buffer is real.** Sprints 11 + 12 exist for a reason. Soft-launch surprises always happen.

## What "demo-able" means each Friday

End-of-sprint Friday demo must include all three:

- A **video walk-through** the client can replay (screen recording from your phone simulator + 2-min voiceover)
- A **coverage report** from `./scripts/coverage.sh` showing % complete (counts + hours)
- A **stoplight summary** — what worked, what slipped, what's blocked (3 bullets each, max)

Mid-sprint Friday sync (week 1 end) is optional but recommended — 15-min "here's the screen, here's the bit that's wobbly" to keep the client in the loop and surface concerns early.

## The 13 sprints (Sprint 0 + 12 build sprints)

| #   | Dates                                               | Theme                                                                                                                                                                                                                                                                                                                         | Hours                                                                               | Friday demo (week 2)                                                                                                                                                                                                                                                                                                                                          |
| --- | --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0   | Mon 1 Jun → Fri 19 Jun                              | Foundation, AI setup, security tooling, repo, plan (extended +1 week for research catch-up)                                                                                                                                                                                                                                   | ~80 (already spent — not counted vs v1.1 budget)                                    | Repo walkthrough → ADRs 005-008 → audit docs → custom skills → security gates → brand theme → PLAN.md → confirm Sprint 1 readiness                                                                                                                                                                                                                            |
| 1   | Mon 22 Jun → Fri 3 Jul                              | **Backend Auth Foundation (no mobile)** — NestJS scaffold, JWT, MockOtpService, OAuth backend, JwtAuthGuard, RolesGuard, AuditLog + **DB-level immutability** + **account lockout (M-231)**, shared infra, **Flutter Web target + responsive base + web auth (cookie+CSRF)**                                                  | ~91 (+9h Flutter Web foundation; +2h M-231 per Estimation v1.2 verification)        | **Foundation demo (technical):** Postman walkthrough → Swagger UI → signup/login/refresh/logout → DB shows User + AuditLog → MockOtpService + 3 safety guards → CI + Semgrep + security-review green → Flutter Web shell loads in Chrome → account lockout test fires (5 fail OTPs → 1h block)                                                                |
| 2   | Mon 6 Jul → Fri 17 Jul                              | **First user-visible sprint:** Mobile + Web Auth + Onboarding + Client→Tasker + Stripe Connect + ABN/ABR + **cross-cutting (PostHog, Sentry, deep linking, a11y foundations)** + **Flutter Web parity** + **AI Welcome Agent (M-228)** + **Sentry PII scrubbing (DEV-12)**                                                    | ~133 (+20h Flutter Web parity, +7h M-228 + DEV-12 per Estimation v1.2 verification) | **First "click through the app" demo (mobile + web):** cold-launch → 3-screen welcome → AI Welcome Agent walks user through onboarding → email/Google/Apple signup → OTP → role select → "Become a tasker" → Stripe Connect → ABN entry. **Same flow on web in Chrome side-by-side.**                                                                         |
| 3   | Mon 20 Jul → Fri 7 Aug (3 weeks)                    | Job posting + AI extraction + **guest mode** + **AI infrastructure cluster (LLM router AI-01, Langfuse, prompt versioning + eval harness, cost quotas, output validators, injection defense)** + **Flutter Web parity** + **Next.js SEO phase 1** + **PII blur on photos (B-44b)** + **supply soft-block + waitlist (M-234)** | ~255 (+16h per Estimation v1.2 verification: AI-01 +8, M-234 +4, B-44b +4)          | **Guest** browses feed (mobile + web) → posts a job with photos → AI extraction → ReAct → "Sign up to publish". Plus: Langfuse traces, prompt-eval CI, cost quotas, PII blur visible on test photo with phone number → blurred. Supply soft-block scenario: zero-supply category → waitlist.                                                                  |
| 4   | Mon 10 Aug → Fri 21 Aug                             | Discovery + Offering + Public Q&A + **License verification module + offer-time guard + expiry cron** + **Flutter Web parity** + **Feature store THIN (AI-05 re-scoped IN)**                                                                                                                                                   | ~145 (+24h: Flutter Web parity +16, AI-05 THIN +8 per Estimation v1.2 verification) | Tasker sees ranked feed + map (mobile + web) → makes an offer → offer-time guard fires for unlicensed plumbing → admin approves → "Verified Plumber" badge. Builder conditional rule demo'd $4K (no licence) vs $7K (licence required). Plus: feature store nightly refresh visible — win rate, response time, completion rate populating per tasker.         |
| 5   | Mon 24 Aug → Fri 4 Sep                              | Messaging + Payments core + **OTP swap to real provider** + **webhook DLQ + regex evasion corpus** + **Flutter Web parity** + **payment lifecycle edge cases (B-56)** + **moderation pipeline orchestrator (B-53)**                                                                                                           | ~171 (+12h per Estimation v1.2 verification: B-56 +8, B-53 +4)                      | Live chat (mobile + web) → off-platform warning fires → card added on web via Stripe Elements → PaymentIntent + SetupIntent → mock OTP swapped for real provider → failed webhook lands in DLQ. Plus: dispute-hold reserve state demonstrated; PAYOUT_READY gate blocks completion if Connect isn't ready; moderation orchestrator fan-out visible in BullMQ. |
| 6   | Mon 7 Sep → Fri 18 Sep                              | Job execution + Completion + Tax/RCTI/GST/ATO + **Flutter Web parity** + **annual income statement (M-233 + B-55)** + **TFN encryption (B-54)**                                                                                                                                                                               | ~119 (+16h per Estimation v1.2 verification: M-233 +2, B-54 +6, B-55 +8)            | Tasker geofence check-in → completion proof → auto-capture → tax invoice + RCTI PDFs (mobile + web) → income statement download for the financial year. TFN stored AES-encrypted via Key Vault — verified via `SELECT * FROM users` showing ciphertext.                                                                                                       |
| 7   | Mon 21 Sep → Fri 2 Oct                              | Reviews + Disputes (Tier-0 mediator) + **Flutter Web parity** + **behavioural fraud scoring (B-48 — re-scoped IN)** + **auto-suspend trigger rules (B-57)**                                                                                                                                                                   | ~119 (+16h per Estimation v1.2 verification: B-48 +10, B-57 +6)                     | Reviews → dispute opened on web → AI proposes resolution → admin co-pilot. Plus: tasker with 3 disputes lost auto-suspended → reinstatement queue (S9 surface). Fraud score visible on admin profile.                                                                                                                                                         |
| 8   | Mon 5 Oct → Fri 16 Oct                              | Notifications + Trust/Safety + Privacy + **per-class retention crons + push token rotation** + **Flutter Web parity** + **device fingerprinting (M-229 — re-scoped IN)** + **versioned consent (M-230)** + **RAG support agent (#194 — re-scoped IN)**                                                                        | ~144 (+21h per Estimation v1.2 verification: M-229 +3, M-230 +4, RAG +14)           | Push on iOS/Android/Safari/Chrome Web → DSR download → consent ledger shows versioned ToS acceptances → retention crons hard-delete a 2y+ thread → device fingerprint visible on admin → RAG agent answers "how do I become a tasker?" without human.                                                                                                         |
| 9   | Mon 19 Oct → Fri 30 Oct                             | Admin console end-to-end + **webhook DLQ replay viewer + bull-board + weekly/monthly reports** + **AP-09b / AP-47b / AP-56 (re-scoped) / AP-57 / AP-58 / AP-59 / AP-52 NL report builder (re-scoped) / AP-53 24-tile super dashboard (re-scoped)**                                                                            | ~149 (+58h per Estimation v1.2 verification)                                        | Admin reviews KYC + License queues → resolves dispute → processes refund (>$1k triggers Super Admin approval) → manages promo codes → exports ATO SERR → reinstates auto-suspended tasker → FSE admin scoped view → Super User Dashboard (24 tiles) on login → NL report builder asks "Top 10 categories by GMV last month" → instant table + CSV export.     |
| 10  | Mon 2 Nov → Fri 13 Nov                              | DevOps + Cloud deploy + WAF + **Terraform IaC (DEV-09)** + **CMK for sensitive docs (DEV-13)**                                                                                                                                                                                                                                | ~91 (+16h per Estimation v1.2 verification: DEV-09 +14, DEV-13 +2)                  | Same flows running against Azure staging + Cloudflare WAF + private DB endpoints. Plus: `terraform apply` recreates the entire dev environment from scratch. KYC blob containers verified encrypted with CMK.                                                                                                                                                 |
| 11  | Mon 16 Nov → Fri 4 Dec (3 weeks)                    | TestFlight + bug fix + soft-launch prep + **onboarding polish** + **maintenance mode + offline indicator + a11y audit + scoped pre-launch pen test** + **full SEO bundle (programmatic location×category, AI auto-SEO, cookie consent, web a11y, sitemap)** + **Flutter Web final polish (browser matrix, PWA manifest)**     | ~143 (+60h SEO + Web final per re-scope)                                            | Client installs via TestFlight + Play Store, runs happy path on device. **Same flow on web (Safari, Chrome, Edge, Firefox).** SEO pages visible in Google Search Console with first indexed pages. A11y audit report committed. Scoped pre-launch pen test complete.                                                                                          |
| 12  | Mon 7 Dec → Fri 8 Jan (3 weeks incl. Xmas/NY break) | Soft launch + first real users + retrospective                                                                                                                                                                                                                                                                                | ~50                                                                                 | First real tasker takes a job in one Sydney suburb (mobile or web), end-to-end with real money (test mode → live). **Note:** 3 weeks elapsed but only ~10 working days because of Christmas + New Year window — most of the time is monitoring + bugfix rather than new build.                                                                                |

**Total: ~1614 hours** across Sprints 1-12 (Estimation v1.2 raw hours = 1,420; we're modestly above because our Flutter Web parity rows are generously budgeted and the AI cluster + cross-cutting infra additions stack on top of the estimate's per-row figures). Delta vs v1.1 (945h): +20h Sprint 3 guest-mode, +13h Sprints 2 + 11 onboarding screens, +5h Sprint 5 OTP swap, +21h Sprint 4 License per ADR 005, +94h Sprint 1/2 rebalance, **+132h Jun 2026 scope reconciliation**, **+162h 14 Jun founder re-scope of Flutter Web + Next.js SEO + AI auto-SEO**, **+180h 14 Jun direct Estimation v1.2 verification** (8 V2 items pulled back IN: B-48, M-229, AP-56, #194 RAG, AP-52, AP-53, AI-05, B-53; 19 items added: M-228, M-230, M-231, M-233, M-234, B-44b, B-54, B-55, B-56, B-57, AP-09b, AP-47b, AP-57, AP-58, AP-59, AI-01, DEV-09, DEV-12, DEV-13), **+42h Estimation v1.2 final audit pass** (21 small items added: KYC rows 26/27 to S2, profile rows 32/50/51 to S2, row 149 cancellation history to S6, settings rows 178-181 to S8, FAQ rows 190-193 to S8, row 196 build info to S11, SEO-18 Core Web Vitals to S11, SEO-19 GA4/Pixel to S11, DEV-07 SLA monitoring to S10, DEV-08 log aggregation to S10, DEV-11 compute topology to S10). Sprint 0 is foundation overhead, not counted vs v1.1 budget. **Soft launch remains Fri 8 Jan 2027 — absorbed into existing sprints, no further calendar slip.** Founder direction: work will be shared across multiple devs, so capacity is not the constraint.

**Coverage status:** every IN, IN★, and THIN row from Estimation v1.2 (398 in-scope items across 8 components) now has either an explicit ID literal in a sprint doc, or coverage under a different ID with the cross-reference noted in [`post-mvp-deferred.md`](./post-mvp-deferred.md). Verified via direct row-by-row audit on 14 Jun 2026.

**Why this restructure (backend-first auth):** Sprint 1 was originally mobile-heavy onboarding which forced building against a non-existent API and refactoring later. Backend-first means: (1) auth API + JWT + RBAC + AuditLog are nailed down before any mobile code, (2) mobile sprints integrate against a real API not mocks, (3) S1 demo is Postman/Swagger/DB — legitimate for a technical client and frames "foundation that saves three weeks of mobile rework", (4) from Sprint 2 onward every Friday demo is "click through the app and see real flows". Tradeoff: Sprint 1 has no user-facing UI. Mitigated by parallel work during S1 — Notifyre alpha sender application (5-7 business day lead time) and tax-advisor RFP (soft-engagement). Stripe, Apple, and Google accounts are already in place; lawyer engagement deferred to Sprint 11 (self-drafted ToS + Privacy Policy in S8 first, lawyer reviews in S11 before live mode).

## Sprint themes — detailed

### Sprint 0 — Foundation, AI setup, security tooling (Mon 1 Jun → Fri 19 Jun, extended 1 week) — IN PROGRESS

**Goal:** Everything that must exist before feature work can start. Foundation isn't billable against the v1.1 estimate — it's prerequisite plumbing.

**Delivered so far:**

- Monorepo scaffold: pnpm workspaces + Turborepo, four apps (mobile/api/admin/web), four packages (prisma/types/tsconfig/eslint-config)
- Prisma schema with 9 models (Country, User, UserSkill, Category, Job, JobPhoto, JobQuestion, Offer, Review, AuditLog), cuid2 IDs, integer cents, soft delete, pgvector
- Migration `000_enable_pgvector` + initial migration applied to local Postgres 17
- 4 ADRs (monorepo & stack, database conventions, multi-country readiness, category types)
- 19 IT audit docs (encryption, IR, BCP/DR, retention, DSR, access control, vendor list, edge security, security-by-stage, etc.)
- 6 custom Claude Code skills: `stripe-payment`, `au-tax`, `pgvector-match`, `tier0-dispute`, `multimodal-extraction`, `security-review`
- Security tooling: Semgrep (18 JOBBees-specific rules + registry rules), CI workflow, PR template with section-by-section reviewer checklist, gitleaks pre-commit
- ESLint v9 flat config, pnpm-workspace consolidation, Dependabot policy (monthly minor/patch only, no major bumps)
- Local dev: Docker Compose for Postgres + Redis, seed data (1 admin + 5 clients + 10 taskers + 20 jobs + 39 offers)
- Privacy audit complete: no personal/financial info in committed files
- Repo on GitHub: https://github.com/rahulkr/jobbees — initial commit pushed
- Coverage script `scripts/coverage.sh` + sprint plan (this doc) + Sprint 1 detail

**Still to land Sprint 0 (D8-D10):**

- ~~Resolve KYC vendor decision~~ ✅ **RESOLVED** — Stripe Connect + ABN + manual per-category license verification. No identity vendor. See ADR 005.
- ~~Resolve auth-token storage decision~~ ✅ **RESOLVED** — Bearer for mobile, HttpOnly cookie + CSRF for web/admin. See ADR 006.
- Confirm OAuth client IDs (Google + Apple) and Notifyre alpha sender ID application
- Brand theme locked from RN prototype with Material 3 modernization (`apps/mobile/lib/theme/`, `docs/brand/`)
- License verification model fully designed (ADR 005 Accepted, conditional Builder rule + schema additions in `packages/prisma/schema.prisma` FUTURE MODELS)
- Tag `sprint-00-end` on `main` after final commit Friday 19 Jun

**Sprint 0 demo (Fri 19 Jun):** see `docs/sprints/sprint-00-foundation-and-setup.md` for full script.

**Hours spent: ~80** (foundation work, not billed against the 945-hour build budget; +10h vs original estimate due to research catch-up — license verification design, ADRs 005-008 cycles, brand theme lock-in).

### Sprint 1 — Backend Auth Foundation (Mon 22 Jun → Fri 3 Jul)

**Backend-only. No mobile code in this sprint.** The auth surface is the riskiest foundational piece — getting it solid before any UI work means the mobile sprints (Sprint 2+) integrate against a real API instead of mocks, with zero rework when reality diverges from the mock.

Backend: NestJS scaffold (app module, config, pino logger, global exception filter), User + Session + RefreshToken + AuditLog models migrated, JWT (15min access / 30d refresh) with rotation on refresh, password hashing (argon2id), MockOtpService (`000000` in dev, 3 safety guards per ADR 008 — startup assertion + Semgrep rule + AuditLog), social-auth backend (Google + Apple ID token verification, user upsert), email signup/verify, login, logout (server-side session revoke), `/me` endpoint, JwtAuthGuard, RolesGuard, AuditLog interceptor (skill §I), idempotency interceptor (Redis-backed, 24h TTL), per-route rate limit guard, error mapping, OpenAPI/Swagger setup, integration tests covering happy + 401 + 403 + idempotency replay + invalid signature.

Admin: admin login + session timeout gate only (just the door — full admin UI comes in S9).

**Inventory IDs:** Backend 228-237, 239, 242, 245-246. Admin 420, 424. (Mobile 1-7, 9-14, 16, 18-20, 28-34 deferred to Sprint 2.)

**Out of scope (deferred):**

- Mobile onboarding + auth screens (S2)
- Tasker upgrade flow (S2)
- Tasker profile (S2)
- KYC / Stripe Connect (S2)
- Real OTP provider (S5 — MockOtpService keeps Sprint 1-4 dev unblocked)

**Open decisions before kick-off:** none — ADRs 005-008 locked in Sprint 0. Auth-token strategy already decided (Bearer for mobile, HttpOnly cookie + CSRF for web/admin — ADR 006).

**Parallel work during Sprint 1 (non-coding, runs alongside):**

- Figma mockups of welcome carousel + auth screens (use `docs/brand/` theme tokens)
- Stripe Connect AU platform application (5-10 business days lead time)
- Notifyre `JOBBEES` alpha sender ID application (5-7 business days)
- Apple Developer Program enrolment
- Lawyer engagement for ToS + Privacy Policy
- Tax advisor RFP

**Friday demo (Fri 3 Jul) — "Foundation demo":** Postman collection walkthrough (signup → email verify → login → refresh → logout → role grant → `/me`) → Swagger UI live → DB query showing User + Session + AuditLog rows → MockOtpService accepting `000000` in dev with all 3 safety guards green → security-review skill output → CI green. Stoplight: foundation solid, mobile starts Monday. See `sprint-01-onboarding-and-auth.md` (will be renamed `sprint-01-backend-auth-foundation.md`).

### Sprint 2 — Mobile Auth + Onboarding + Tasker upgrade backend + Stripe Connect + ABN (Mon 6 Jul → Fri 17 Jul)

**First user-visible sprint.** Mobile starts here, integrating against the Sprint 1 backend that's already stable. License verification deferred to Sprint 4 (where offering lives — the offer-time guard belongs in the offering code).

Mobile: splash, 3-screen welcome carousel, email signup, Google signup, Apple signup, login, OTP entry (against MockOtpService), email verification screen, biometric re-login setup, role select (client / tasker / will-decide), client home shell, force-logout, account-suspended + deletion screens, basic client profile, contextual onboarding tooltips. Plus client→tasker upgrade entry, Stripe Connect onboarding (webview), ABN entry + ABR lookup result screen, full tasker profile setup wizard, service areas, hourly rate, public tasker profile, held-funds banner, Connect reminder cadence (UI). Categories selector flags `requiresLicense: true` and `licenseRequiredOverCents != null` categories visually so taskers know what's coming in S4.

Backend: ABR API integration, Stripe Connect Express, Connect webhook handlers, Connect onboarding status tracking, held-funds calculation, client→tasker upgrade backend. (License module + offer-time guard + expiry cron deferred to S4 with offering.)

Admin: scaffold-level — Stripe Connect status mirror, basic suspend/reinstate buttons. Full admin UI comes in S9.

**Inventory IDs:** Mobile 1-7, 9-14, 16, 18-20, 28-34 (deferred from S1 + new welcome carousel rows), 15, 35-52. Backend 241, 244, 292-295. Admin 431 (Stripe Connect status mirror, read-only thin).

**Out of scope (in Sprint 4 instead):** License module backend, License upload UI (mobile row 41 + new row 531), offer-time guard (row 532), license expiry cron (row 533), admin License review queue (row 534).

**No Day-1 decision gate — verification model is locked.** Per ADR 005: Stripe Connect KYC + ABN (free ABR API) + per-category license verification (manual admin review). License work happens in S4 alongside offering.

**Friday demo (Fri 17 Jul) — "First click-through demo":** cold-launch on simulator → welcome carousel → email signup against real Sprint 1 backend → OTP entry (`000000`) → email verify link → land on client home → toggle biometric re-login → tap "Become a tasker" → Stripe Connect onboarding launches in webview → returns to ABN entry → ABR API verifies → tasker profile setup wizard → public tasker profile rendered → held-funds banner appears (no completed jobs). **Note for client:** "Offering on licensed work like plumbing requires a licence — that ships in Sprint 4 alongside the offering system."

### Sprint 3 — Job posting + AI extraction + guest mode (Mon 20 Jul → Fri 31 Jul)

Mobile: full job-posting flow — category picker, title + description, AI extraction confirmation screen (single-pass), multi-turn ReAct clarifying loop, photo upload (multi), camera-based job creation (vision model), voice-driven posting, location picker + map, date/time, duration estimate (AI), budget input + nudge, special requirements, review + publish, save as draft, resume draft, schedule >7d, edit/cancel posted job. **Plus guest-mode shell, read-only browse, "Sign up to publish" bottom sheet, local draft persistence across signup.**

Backend: job CRUD, AI extraction (Gemini Flash JSON-mode), ReAct multi-turn orchestration, multimodal extraction (Gemini Flash vision → Pro fallback), image upload + Azure Blob (using local filesystem at MVP — Blob swap in S10), geocoding (Google Maps Platform — locked), job state machine, lifecycle audit log, embedding generation on publish (pgvector), job draft persistence, job search endpoint, schedule >7d backend. **Plus public read endpoint with PII filter, anonymous rate limit, and claim-draft-on-signup flow.**

**Inventory IDs:** Mobile 53-72, 74-75, **523, 524 (new)**. Backend 246-260, **525, 526 (new)**.

**Why guest mode is in this sprint:** Industry-standard pattern for AU consumer marketplaces (Airtasker, hipages). ~20-30% lift in signup conversion vs gated-from-start flow. Cheaper to build alongside the posting flow than to retrofit later. See sprint-03 detail doc "Design decision" section.

**⚠️ Risk:** vision extraction + ReAct loop are the largest single-feature builds in the inventory (14h each). Allow slippage into S4 if needed; if both done by end of S3, S4 starts early. Guest mode adds 20h — accommodated by the broader sprint budget.

**Friday demo:** guest cold-launches app (no account) → browses feed → posts a job with photo → AI extraction + ReAct loop → taps Publish → "Sign up to publish" bottom sheet → completes signup → job lands in their fresh account, status PUBLISHED.

### Sprint 4 — Discovery + Offering + Public Q&A + License verification (Mon 3 Aug → Fri 14 Aug)

**License verification lands here**, not in S2 — because the offer-time guard is intrinsically tied to the offering code path. Adding License module to S2 would force splitting it across sprints (upload in S2, guard in S4); landing it all here keeps the work coherent.

Mobile: home feed (ranked), vector matching consumer UI, map view of nearby jobs, list view, filters (category/budget/distance/date), sort options, saved jobs, auto-invite push handling, job share link, hide/not-interested, offer placement screen, own offers list, edit/withdraw offer, offer review (client — list, sort, filter), accept/decline offer, public Q&A under job (replaces negotiation), offer expiry/notifications. **Plus** license upload UI (photo + license number + issuing state + expiry per ADR 005), license status screen, licensed-trade category selector with "License required" chip + deeplink to upload, "Verified [Trade]" badges on tasker profile + offer lists.

Backend: offer CRUD + state machine, offer notification triggers, offer expiry cron, offer validation (one active per tasker per job), vector similarity (pgvector cosine top-K), ranked feed algorithm (weighted blend), auto-invite to matched taskers, proximity calculation, category/skill matching, public Q&A backend. **Plus** License module (upload + admin approval state machine per ADR 005), offer-time license guard (covers unconditional categories AND conditional Builder rule — license required when fixed-price offer ≥ $5K AUD or any hourly offer on Builder), license expiry cron (daily; 14d/7d/1d reminders + auto-EXPIRED transition).

Admin: License Review Queue scaffold (full UI lands in S9 — this is the minimal "PENDING list with approve/reject buttons" so the S4 demo works).

**Inventory IDs:** Mobile 76-87, 88, 90-94, 96-98, 41 (expanded to IN 5h), 531 (new). Backend 261-265, 267-268, 270-273, 260, 240 (License module), 532 (offer-time guard incl. conditional Builder rule), 533 (license expiry cron). Admin 534 (License review queue scaffold).

**Friday demo (Fri 14 Aug):** tasker opens app → ranked feed shows jobs matched to their skills + location → taps a plumbing job → offer screen blocks with "License required" deeplink → tasker uploads plumbing licence → admin (in scaffold queue) approves → tasker makes an offer → client sees the offer with "Verified Plumber" badge → accepts. **Then** demo the conditional rule: same tasker (no builder licence) opens a "build me a deck" job → offer $4,000 → goes through → offer $7,000 → blocked with "License required (over $5K NSW threshold)" message.

### Sprint 5 — Messaging + Payments core (Mon 17 Aug → Fri 28 Aug)

Mobile: inbox/thread list, conversation view (text + photo attachment + file/PDF), read receipts, report user/message, block user, off-platform warning, message search, push notifications for messages, thread freeze on dispute, add/remove card, default card, Apple/Google Pay (Stripe-managed), Stripe-hosted onboarding webview, payout history, earnings summary (tasker), transaction history (client), receipt PDF view.

Backend: Socket.IO single-node + Redis adapter (groundwork only), message persistence, attachment upload + virus scan (local at MVP, swap for Azure Content Safety in S8), thread state machine (open/frozen), off-platform regex detection, thread freeze logic, Stripe PaymentIntent (create/capture/void), Stripe Refund (full + partial), manual capture flow ≤7d (Stripe 7-day window), SetupIntent + saved PaymentMethod for >7d / scheduled jobs, re-authorisation flow on capture expiry, payment state machine, idempotency middleware (Redis-backed), Stripe idempotency key pass-through, webhook signature verification, application fee / platform fee logic.

**Inventory IDs:** Mobile 109-112, 115, 120-125, 126-131, 132-133. Backend 274, 276, 279-281, 283-284, 286-290, 296-299, 302.

**⚠️ Stripe webhook testing.** Use `ngrok` or `cloudflared tunnel` for local Stripe webhook delivery. Zero Azure cost.

**Friday demo:** client + tasker chat in-app → client adds a card → places a payment hold on a job → tasker accepts → client sees "Authorised $250" → demo the re-auth prompt by manually triggering it.

### Sprint 6 — Job execution + Completion + Tax/RCTI/GST/ATO (Mon 31 Aug → Fri 11 Sep)

Mobile: accepted-job screen, status update buttons (en route / arrived / in progress / completed), geofenced check-in / arrival proof, live location share during active job, completion proof upload (2 photos + checklist), tax invoice PDF (client), RCTI PDF (tasker), RCTI agreement screen, refund request, re-auth prompt, promo code input, cancellation flow with fee preview.

Backend: cancellation engine with fee matrix, fee calculation logic, no-show detection (both sides), geofenced check-in verification, auto-confirm cron job, dispute window cron (48h), escalating notification cadence, state transitions for all cancel scenarios, GST calculation on platform fee, ABN status tracking + re-check cron, RCTI generation + PDF (pdfkit), RCTI agreement workflow + consent capture, tax invoice generation + PDF, ATO sharing-economy reporting export (monthly job), tax-rate config, live location share endpoint.

**Inventory IDs:** Mobile 99-105, 134-140, 142-148. Backend 285, 305-322.

**⚠️ Engage tax advisor BEFORE Sprint 6 starts.** This is the only sprint where tax-side work is on the critical path. CLAUDE.md rule 4 mandates tax advisor review before any RCTI/ATO code merges. Schedule the call by end of Sprint 5.

**Friday demo:** tasker walks into geofence (simulate) → checks in → marks complete + uploads 2 photos → auto-capture fires → tax invoice generated as PDF → tasker downloads RCTI → client sees receipt.

### Sprint 7 — Reviews + Disputes (Tier-0 mediator + admin co-pilot) (Mon 14 Sep → Fri 25 Sep)

Mobile: post-completion review prompt (both sides), star rating, text review with min length, blind review with timeout-reveal, response to review, report review, dispute initiation flow, reason picker, evidence upload (photos + message screenshots), dispute conversation thread, AI-proposed resolution screen, accept/reject/escalate, dispute status tracker, resolution outcome screen.

Backend: review CRUD, blind review with timeout-reveal, response-to-review API, review removal API (admin-triggered), minimum-length enforcement, dispute CRUD, dispute state machine, Tier-0 LLM mediator agent (with cost guardrails — see `.claude/skills/tier0-dispute/SKILL.md`), evidence collection API, resolution proposal generation (full/partial/refund), Tier-0 threshold config (≤ AUD $200), accept/reject proposal logic, escalation to human admin, admin case brief generation (co-pilot).

**Inventory IDs:** Mobile 150-153, 155, 157, 158-166. Backend 323-325, 328-338.

**Friday demo:** client completes job → both sides leave reviews → one party opens a dispute → AI mediator analyses thread + evidence + proof → proposes "$50 partial refund because tasker missed one item on checklist" → client accepts → funds released accordingly.

### Sprint 8 — Notifications + Trust/Safety + Privacy (Mon 28 Sep → Fri 9 Oct)

Mobile: push (FCM/APNS) setup, in-app notification center, per-channel toggle, email opt-out (unsubscribe), SMS opt-out (STOP), notification badges, deep-link from notification, critical-state fallback, notification history (thin), DSR access/export, account deletion request.

Backend: push notification service, email service (SendGrid), SMS service (Notifyre), in-app notification queue/API, user preferences engine, notification templates, critical-state fallback escalation (push → email → SMS), Spam Act compliance, unsubscribe token endpoint, image content moderation (Azure Content Safety), async moderation queue, EXIF tampering / consistency check, rate limiting middleware, LLM cost telemetry + anomaly alerts, account suspension webhooks, data inventory + retention schema, DSR endpoints (access, delete, correct), anonymisation job (financial retained 7y), hard delete vs anonymise logic, consent ledger, PII redaction layer before external LLM calls, audit log.

**Inventory IDs:** Mobile 168-170, 172-176, 185-186. Backend 341-365.

**⚠️ Risk:** EXIF tampering + content moderation are the only places we hit Azure Content Safety. Local filesystem still works for storage; just call Content Safety from the API. Small Azure spend (~$5-15) during S8 — acceptable.

**Friday demo:** demonstrate "Privacy & Data" screen — request data export, see consent history, request deletion → backend anonymises → audit log shows the chain.

### Sprint 9 — Admin console end-to-end (Mon 12 Oct → Fri 23 Oct)

Admin: dashboard (today's queue), user list + detail, KYC review queue, Connect onboarding tracker, suspend/reinstate user, DSR request handler, job list + detail + edit/delete, content moderation queue, manual approval, force-cancel, edit AI extraction, offer list per job, public Q&A moderation queue, flagged messages queue, manual message review, thread freeze, payment list + detail, refund processing, manual capture/void, held-funds dashboard, promo code admin, tax invoice listing, RCTI status, ATO report preview/download, ATO submission log, GST rate config, dispute queue, Tier-0 suggestion panel, manual mediation, evidence viewer, resolution actions, admin notes, admin co-pilot brief renderer, review queue (flagged), manual review removal, FAQ CRUD, T&Cs versioned editor, category CRUD, sub-category CRUD, service area CRUD, platform fee config, cancellation fee matrix config, auto-confirm timing config, Tier-0 dispute threshold, manual broadcast tool, admin action audit log viewer, DSR request queue.

**Inventory IDs:** Admin 426-432, 433-437, 441-448, 450-457, 458, 460, 463, 464-468, 471-477, 480-482, 485-486, 491-494, 497-500, 507, 511, 514.

**Friday demo:** record a "day in the life of admin" — login → check today's queue → approve a KYC → resolve a dispute using Tier-0 suggestion → process a refund → export ATO report.

### Sprint 10 — DevOps + Cloud deploy + WAF (Mon 26 Oct → Fri 6 Nov)

Terraform: Azure App Service (3 apps), Azure Database for PostgreSQL Flexible (with pgvector), Azure Cache for Redis, Azure Blob Storage, Azure Key Vault, Azure Content Safety, Azure App Insights, VNet + private endpoints, NSGs. Cloudflare Pro setup: WAF rules per `docs/audit/edge-security.md`, DDoS, Bot Fight, geo-restrict admin, rate limits at edge. CI/CD: GitHub Actions pipelines (lint/test/typecheck on every PR, deploy to staging on merge to main, deploy to prod on tag), Prisma migrate deploy in CI, blob storage swap in (replace local filesystem with Azure Blob SDK calls), Key Vault references in App Service config, secrets rotation policy, encryption at rest verification, OpenAPI docs generation, health check endpoints, status page (thin).

**Inventory IDs:** Backend 403-419. Admin 501-505 (config flags). Plus `docs/audit/edge-security.md` implementation.

**Cost from this sprint onwards:** ~$300-400/mo Azure + $25/mo Cloudflare Pro. **First month with real spend.** Document burn rate weekly.

**Friday demo:** same end-to-end happy-path flow demoed in Sprint 6 — but now running on Azure staging behind Cloudflare WAF. No localhost. The client sees a public URL.

### Sprint 11 — TestFlight + bug fix + soft-launch prep (Mon 9 Nov → Fri 20 Nov)

TestFlight: Apple Developer Program enrolment if not done, signing certificates, App Store Connect setup, TestFlight internal testers (you + client + 2-3 trusted testers), upload first build. Google Play: internal testing track, signing key, upload AAB. Mobile polish: app icon final, splash, launch animation, App Store + Play Store listing screenshots, App Tracking Transparency prompt iOS. Bug fix: every issue surfaced during testing — expect 30-50 small ones in week 1. Final compliance check: re-run `security-review` skill on all code, run Semgrep + CodeQL, run `pnpm audit` for npm CVEs. Documentation pass: PROJECT_CONTEXT.md, README, contributing guide for if another dev joins.

**Inventory IDs:** Mobile 198-205 (legal pages), 206-227 (cross-cutting), 225-227 (icons, screenshots, ATT prompt). SEO 516-521.

**Friday demo:** client installs the app on their iPhone via TestFlight invite, runs the happy path end-to-end, reports back. We file bugs and fix them next sprint.

### Sprint 12 — Soft launch + first real users + retrospective (Mon 23 Nov → Fri 4 Dec)

Soft launch logistics: pick a Sydney suburb (Newtown? Surry Hills?), onboard 30-50 taskers via manual outreach + admin invitation tool, switch Stripe from test mode to live mode (one-way decision — set a calendar reminder + checklist), monitor App Insights + Cloudflare logs daily, run a daily "what broke today" 30-min standup with yourself + client.

End-of-MVP audit: run `./scripts/coverage.sh` — every IN/IN★ row should be `done [sprint-N, PR#nn]`. Anything not done needs written justification in `docs/sprints/post-mvp-deferred.md`. Hand-off to ongoing maintenance.

Retrospective: what went well, what didn't, what's the post-MVP roadmap. Documented as `docs/sprints/retrospective.md` (committed).

**Friday demo (final):** real tasker in Sydney completes a real job posted by a real client, with real money flowing (real test card, then real card). Both sides leave reviews. Tax invoice generated, RCTI sent. Demo recorded as the launch video.

## Tracking — how this never loses a feature

### Inventory CSV columns

| Col   | Name              | Role                                                                         |
| ----- | ----------------- | ---------------------------------------------------------------------------- |
| 1     | ID                | Row identifier (referenced from PRs and sprint docs)                         |
| 2     | Surface           | Mobile / Backend / Admin / SEO                                               |
| 3     | Section           | e.g., "1.1 Onboarding & Auth"                                                |
| 4     | Item              | The feature itself                                                           |
| 5     | Architect Note    | Original gap reference from review                                           |
| 6     | Call              | IN / IN★ / THIN / POST / DROP / MANUAL                                       |
| 7     | Hours             | Estimate                                                                     |
| 8     | Notes / Reason    | Why this scope, why this hours estimate                                      |
| **9** | **Your Decision** | **Used as completion marker. Set to `done [sprint-N, PR#nn]` when shipped.** |
| 10    | Your Comment      | Per-row notes / commentary                                                   |

### Friday closing ritual

Every Friday afternoon (mid-sprint OR end-of-sprint):

1. Open `inventory/JOBBees_Feature_Inventory.csv`
2. For every feature you completed this week, set column 9 to `done [sprint-N, PR#nn]`
3. Run `./scripts/coverage.sh` and `./scripts/coverage.sh --by-sprint N`
4. Run `./scripts/coverage.sh --by-section` to spot lagging areas
5. Paste output into the Friday client email
6. If end-of-sprint: also run `./scripts/coverage.sh --remaining > /tmp/remaining.txt` and review what's still outstanding

### End-of-MVP gate

Before declaring MVP done in Sprint 12:

- [ ] `./scripts/coverage.sh` reports ≥98% of IN+IN★ done
- [ ] Any remaining IN+IN★ rows have a written justification in `docs/sprints/post-mvp-deferred.md`
- [ ] Compliance docs (`docs/audit/*.md`) review owners filled in
- [ ] ADRs 001-004 (and 005 once KYC is decided) reviewed
- [ ] All custom skills (.claude/skills/\*) reviewed for currency
- [ ] CI pipelines all green on `main` for last 7 days
- [ ] Pen test booked for post-launch (within 60 days)

## Open decisions — must be resolved before the sprint that depends on them

| Decision                                      | Needed before                                                                                             | Status                                                                                                                                                                                                                                      | ADR / home                          |
| --------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| ~~KYC vendor~~                                | n/a                                                                                                       | ✅ RESOLVED — Stripe Connect + ABN + manual license per category. No identity vendor.                                                                                                                                                       | `docs/adrs/005-kyc-strategy.md`     |
| ~~Auth token storage~~                        | n/a                                                                                                       | ✅ RESOLVED — Bearer for mobile, HttpOnly cookie + CSRF for web/admin.                                                                                                                                                                      | `docs/adrs/006-auth-tokens.md`      |
| ~~Edge security vendor~~                      | n/a                                                                                                       | ✅ RESOLVED — Cloudflare Pro ($20/mo annual).                                                                                                                                                                                               | `docs/adrs/007-edge-security.md`    |
| Phone OTP production vendor                   | Sprint 5 D1 (Mon 17 Aug)                                                                                  | Pattern locked (MockOtpService), production vendor TBD: Firebase / Notifyre / Twilio                                                                                                                                                        | `docs/adrs/008-otp-sms-strategy.md` |
| Tax advisor engagement                        | Soft-engage (RFP, no commitment) by mid-Sprint 5 (Fri 21 Aug); formal paid review Sprint 11 before launch | Pending — high-priority RFP. Reason: Sprint 6 GST/RCTI/ATO code is the highest AI-hallucination-risk area per CLAUDE.md rule 4. Having an advisor lined up means quick clarifications are possible during S6 even if formal review is later | n/a                                 |
| Lawyer engagement for ToS + Privacy Policy    | Sprint 11 D1 (Mon 9 Nov)                                                                                  | Pending. Strategy: draft Privacy Policy + ToS in Sprint 8 from public templates (Airtasker/hipages style); lawyer in S11 reviews + customizes. Hard deadline: published before Stripe live mode flip in S12                                 | n/a                                 |
| ~~Apple Developer Program enrolment~~         | n/a                                                                                                       | ✅ Already enrolled                                                                                                                                                                                                                         | n/a                                 |
| ~~Google Developer / Play Console enrolment~~ | n/a                                                                                                       | ✅ Already enrolled                                                                                                                                                                                                                         | n/a                                 |
| ~~Stripe account~~                            | n/a                                                                                                       | ✅ Already exists; Connect Express integration uses existing account                                                                                                                                                                        | n/a                                 |
| ~~Geocoding vendor~~                          | n/a                                                                                                       | ✅ RESOLVED — Google Maps (best AU coverage incl. regional NSW + inner-Sydney suburb mix)                                                                                                                                                   | n/a                                 |
| Notifyre `JOBBEES` alpha sender ID            | Sprint 1 D1 (Mon 22 Jun)                                                                                  | Apply during S1 — 5-7 business day approval. Needed for S5 OTP swap + S8 notifications                                                                                                                                                      | n/a                                 |

## Risk register

| Risk                                                           | Likelihood | Impact   | Mitigation                                                                                                                                                                     |
| -------------------------------------------------------------- | ---------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| AI extraction quality below acceptable                         | Medium     | High     | Sprint 3 includes evaluation harness; budget +20h buffer in S3-S4 for prompt iteration                                                                                         |
| Stripe Connect setup blocks on AU compliance review by Stripe  | Low        | High     | Initiate Stripe Connect onboarding application in Sprint 1 — review takes 5-10 business days                                                                                   |
| License-register cross-check is manual + admin-time intensive  | Medium     | Medium   | Admin queue prioritises licensed-trade categories; recommend `Verified [Trade]` badge displays last-checked timestamp + URL so the audit trail lives in the License row itself |
| Vision model cost spike (vision is ~10× text cost)             | Medium     | Medium   | Cost guardrails enforced via `.claude/skills/multimodal-extraction/SKILL.md`; daily cost cap per user + global                                                                 |
| Mobile push notifications break on real iOS (sim is forgiving) | Medium     | Medium   | Sprint 11 TestFlight catches this; budget time in S11 to debug APNS                                                                                                            |
| End-of-MVP soft launch reveals a P0 we missed                  | High       | Medium   | Sprints 11-12 ARE the buffer. Don't over-commit them.                                                                                                                          |
| Tax/RCTI/ATO interpretation differs from tax advisor           | Medium     | Critical | Engage advisor BEFORE Sprint 6 starts (mid-S5). Don't merge without sign-off.                                                                                                  |
| Auto-updater bumps a critical dep mid-sprint                   | Low (now)  | High     | `.github/dependabot.yml` configured for monthly + minor/patch only; majors require manual ADR                                                                                  |

## What we don't do

- **No new features outside the inventory.** "Wouldn't it be cool if..." goes into `docs/sprints/post-mvp-deferred.md`, not into the sprint.
- **No skipping the Friday demo to "ship more code".** The demo is the commitment to the client.
- **No deploying to Azure before Sprint 10.** Local dev only. Stripe in test mode. ngrok for webhooks. This is intentional cost control.
- **No commits to `main` that fail CI.** The gates exist for a reason. If a gate is wrong, fix the gate in its own PR.
- **No bumping major dep versions during sprints.** Patch + minor via Dependabot monthly batched PRs only.
- **No client-confidential or personal info in committed files.** Privacy audit (already done before first commit) stays clean.

## Per-sprint files

Each sprint has its own detail doc:

- `sprint-00-foundation-and-setup.md` — Sprint 0 (foundation, retrospective)
- `sprint-01-onboarding-and-auth.md` — Sprint 1 detail (now backend-only auth foundation — title preserved for file-history continuity; content updated)
- `sprint-02-kyc-tasker-connect.md` — Sprint 2 detail (now mobile auth + onboarding + tasker backend + Stripe Connect + ABN; License module deferred to S4)
- `sprint-03-task-posting-ai.md` — Sprint 3 detail (unchanged scope, dates shifted)
- `sprint-04-discovery-bidding.md` — Sprint 4 detail (now includes License module + offer-time guard + expiry cron per ADR 005)
- `sprint-05-messaging-payments.md` through `sprint-12-soft-launch.md` — dates shifted, scope unchanged

Each sprint doc includes: inventory IDs in scope, definition of done per feature, demo script for Friday, risk + decision callouts, link to the PRs that landed.

## References

- `PROJECT_CONTEXT.md` — full architectural context
- `CLAUDE.md` — hard rules (CLAUDE.md rule 2 = manual review of payment/tax/PII, etc.)
- `docs/adrs/` — architecture decisions
- `docs/audit/` — IT audit documentation
- `inventory/JOBBees_Feature_Inventory.csv` — 522-row feature list (gitignored)
- `scripts/coverage.sh` — Friday coverage report
