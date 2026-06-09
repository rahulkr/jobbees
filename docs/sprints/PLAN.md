# JOBBees — MVP Sprint Plan

**Project kick-off:** Mon 1 Jun 2026
**Cadence:** 2-week sprints
**Sprint 0 (setup):** Mon 1 Jun → Fri 12 Jun 2026 (in progress, ends Fri 12 Jun)
**Sprint 1 (first build sprint):** Mon 15 Jun 2026
**Sprint 12 (final):** Fri 27 Nov 2026
**Total delivery: 13 sprints** = 1 setup + 12 production build sprints = 26 weeks
**Demo cadence:** End-of-sprint Friday afternoon, weekly mid-sprint Friday optional sync
**Tracker:** `inventory/JOBBees_Feature_Inventory.csv` (gitignored) updated each Friday
**Coverage script:** `./scripts/coverage.sh` (run before client call)

## Sprint 0 vs Sprints 1-12

Sprint 0 is the **foundation sprint** — it isn't part of the 12-sprint build budget. It covers everything that has to be in place before feature work starts: monorepo scaffold, schema, ADRs, IT audit documentation, custom AI tooling, security gates, CI, repo on GitHub, plan + coverage tracker. It's been running since Mon 1 Jun and wraps Fri 12 Jun.

Sprints 1-12 are the **feature build budget** — these consume the ~945-hour estimate from v1.1.

The client gets a Sprint 0 wrap demo on Fri 12 Jun showing: repo layout, plan, security gates, ADRs, audit docs. That demo also surfaces the open decisions that block Sprint 1 (KYC vendor, OAuth client IDs, Notifyre alpha sender, auth-token storage strategy).

## Operating principles

1. **Vertical slices, not horizontal layers.** Every sprint produces something the client can click through on the mobile app or admin console. No "invisible backend" sprints.
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

| #   | Dates              | Theme                                                 | Hours | Friday demo (week 2)                                                                                          |
| --- | ------------------ | ----------------------------------------------------- | ----- | ------------------------------------------------------------------------------------------------------------- |
| 0   | Mon  1 Jun → Fri 12 Jun | Foundation, AI setup, security tooling, repo, plan | ~70 (already spent — not counted vs v1.1 budget) | Repo walkthrough → ADRs → audit docs → custom skills → security gates → PLAN.md → confirm Sprint 1 readiness |
| 1   | Mon 15 Jun → Fri 26 Jun | Onboarding & Auth                                | ~90   | Open app → email signup → OTP/verify → role select → poster home → biometric re-login                         |
| 2   | Mon 29 Jun → Fri 10 Jul | KYC + Tasker upgrade + Stripe Connect onboarding | ~85   | Poster → upgrade to tasker → KYC flow (Didit or manual) → ABN entry → held-funds banner → Connect onboarding  |
| 3   | Mon 13 Jul → Fri 24 Jul | Task posting + AI extraction                     | ~110  | Poster posts a task with photos → AI auto-categorises + suggests budget → ReAct clarifying questions → publish |
| 4   | Mon 27 Jul → Fri  7 Aug | Discovery + Bidding + Public Q&A                 | ~100  | Tasker sees ranked feed + map → places a bid → poster sees bid list, sorts, accepts → public Q&A under task   |
| 5   | Mon 10 Aug → Fri 21 Aug | Messaging + Payments core                        | ~115  | Live chat between poster + tasker → off-platform warning fires → card added → PaymentIntent + SetupIntent     |
| 6   | Mon 24 Aug → Fri  4 Sep | Job execution + Completion + Tax/RCTI/GST/ATO    | ~95   | Tasker geofence check-in → completion proof upload → auto-capture → tax invoice PDF + RCTI PDF                |
| 7   | Mon  7 Sep → Fri 18 Sep | Reviews + Disputes (Tier-0 mediator)             | ~95   | Both sides leave reviews (blind, timeout-reveal) → dispute opened → AI proposes resolution → admin co-pilot   |
| 8   | Mon 21 Sep → Fri  2 Oct | Notifications + Trust/Safety + Privacy           | ~85   | Push fires on bid/accept/dispute → EXIF flags suspicious photo → DSR export download → consent ledger         |
| 9   | Mon  5 Oct → Fri 16 Oct | Admin console end-to-end                         | ~85   | Admin reviews KYC queue → resolves dispute → processes refund → manages promo codes → exports ATO report     |
| 10  | Mon 19 Oct → Fri 30 Oct | DevOps + Cloud deploy + WAF                      | ~75   | Same flows running against Azure staging + Cloudflare WAF + private DB endpoints                              |
| 11  | Mon  2 Nov → Fri 13 Nov | TestFlight + bug fix + soft-launch prep          | ~60   | Client installs the app on their phone via TestFlight + Play Store internal track, full happy path on device  |
| 12  | Mon 16 Nov → Fri 27 Nov | Soft launch + first real users + retrospective   | ~50   | First real tasker posts a task in one Sydney suburb, end-to-end with real money (test mode → live)            |

**Total: ~945 hours** (matches estimate v1.1 within 5%, includes buffer in S11-12).

## Sprint themes — detailed

### Sprint 0 — Foundation, AI setup, security tooling (Mon 1 Jun → Fri 12 Jun) — IN PROGRESS

**Goal:** Everything that must exist before feature work can start. Foundation isn't billable against the v1.1 estimate — it's prerequisite plumbing.

**Delivered so far:**

- Monorepo scaffold: pnpm workspaces + Turborepo, four apps (mobile/api/admin/web), four packages (prisma/types/tsconfig/eslint-config)
- Prisma schema with 9 models (Country, User, UserSkill, Category, Task, TaskPhoto, TaskQuestion, Bid, Review, AuditLog), cuid2 IDs, integer cents, soft delete, pgvector
- Migration `000_enable_pgvector` + initial migration applied to local Postgres 16
- 4 ADRs (monorepo & stack, database conventions, multi-country readiness, category types)
- 19 IT audit docs (encryption, IR, BCP/DR, retention, DSR, access control, vendor list, edge security, security-by-stage, etc.)
- 6 custom Claude Code skills: `stripe-payment`, `au-tax`, `pgvector-match`, `tier0-dispute`, `multimodal-extraction`, `security-review`
- Security tooling: Semgrep (18 JOBBees-specific rules + registry rules), CI workflow, PR template with section-by-section reviewer checklist, gitleaks pre-commit
- ESLint v9 flat config, pnpm-workspace consolidation, Dependabot policy (monthly minor/patch only, no major bumps)
- Local dev: Docker Compose for Postgres + Redis, seed data (1 admin + 5 posters + 10 taskers + 20 tasks + 39 bids)
- Privacy audit complete: no personal/financial info in committed files
- Repo on GitHub: https://github.com/rahulkr/jobbees — initial commit pushed
- Coverage script `scripts/coverage.sh` + sprint plan (this doc) + Sprint 1 detail

**Still to land Sprint 0 (D8-D10):**

- Resolve KYC vendor decision (Didit / manual) → ADR 005
- Resolve auth-token storage decision → ADR 006
- Confirm OAuth client IDs (Google + Apple) and Notifyre alpha sender ID application
- Tag `sprint-00-end` on `main` after final commit Friday 12 Jun

**Sprint 0 demo (Fri 12 Jun):** see `docs/sprints/sprint-00-foundation-and-setup.md` for full script.

**Hours spent: ~70** (foundation work, not billed against the 945-hour build budget).

### Sprint 1 — Onboarding & Auth (Mon 15 Jun → Fri 26 Jun)

Mobile: splash, signup (email/Google/Apple), login, OTP entry, email verify, biometric, role select, force-logout, account-suspended/deletion screens, basic poster profile.

Backend: user CRUD, OAuth providers, JWT + refresh rotation, password hashing/reset, OTP service, role-based permissions, suspension/ban, session revoke.

Admin: admin login + session timeout (just the gate, the rest comes in S9).

**Inventory IDs:** Mobile 1-7, 9-14, 16, 18-20, 28-34. Backend 228-237, 239, 242, 245-246. Admin 420, 424.

**Out of scope (deferred):** KYC (S2), tasker upgrade flow (S2), tasker profile (S2), task posting (S3).

**Open decisions before kick-off:**

- OTP provider for SMS: Notifyre confirmed. Email OTP: SendGrid.
- Auth tokens: JWT in HttpOnly cookie? Or Bearer header for mobile? **Default: Bearer for mobile, HttpOnly cookie for web/admin.** Confirm in S1 day 1.

**Friday demo script:** see `sprint-01-onboarding-and-auth.md`.

### Sprint 2 — KYC + Tasker upgrade + Stripe Connect onboarding (Mon 29 Jun → Fri 10 Jul)

Mobile: poster→tasker upgrade entry, KYC flow (whichever path is decided), ID upload, selfie + liveness (Didit path) OR manual document upload (manual path), ABN entry + ABR lookup, KYC status screen, manual review prompt, KYC re-submission, full tasker profile setup wizard, service areas, hourly rate, public tasker profile, Stripe Connect entry, held-funds banner, Connect reminder cadence (UI).

Backend: KYC orchestration (Didit webhook OR admin manual review queue), ABR API integration, Stripe Connect Express, Connect webhook handlers, Connect onboarding status tracking, held-funds calculation, poster→tasker upgrade backend.

**Inventory IDs:** Mobile 15, 21-27, 35-52. Backend 240-241, 244, 292-295.

**⚠️ KYC decision gate — Day 1 of Sprint 2.** Two paths:

- **Didit** ($0.33/check, 500 free/month, SOC 2 + ISO + iBeta certified) → integration takes ~13-15h, less PII stored on JOBBees side
- **Manual review queue** → admin builds approval UI, taskers upload docs, JOBBees stores redacted refs only → takes ~24-27h

Decision recorded in `docs/adrs/005-kyc-strategy.md` once made. **Status as of today: not decided.**

**Friday demo:** poster opens app → "Become a tasker" CTA → KYC flow runs end-to-end → verified badge appears → Stripe Connect onboarding launches → held-funds banner appears (because Connect not complete yet).

### Sprint 3 — Task posting + AI extraction (Mon 13 Jul → Fri 24 Jul)

Mobile: full task-posting flow — category picker, title + description, AI extraction confirmation screen (single-pass), multi-turn ReAct clarifying loop, photo upload (multi), camera-based task creation (vision model), voice-driven posting, location picker + map, date/time, duration estimate (AI), budget input + nudge, special requirements, review + publish, save as draft, resume draft, schedule >7d, edit/cancel posted task.

Backend: task CRUD, AI extraction (Gemini Flash JSON-mode), ReAct multi-turn orchestration, multimodal extraction (Gemini Flash vision → Pro fallback), image upload + Azure Blob (using local filesystem at MVP — Blob swap in S10), geocoding (Mapbox), task state machine, lifecycle audit log, embedding generation on publish (pgvector), task draft persistence, task search endpoint, schedule >7d backend.

**Inventory IDs:** Mobile 53-72, 74-75. Backend 246-260.

**⚠️ Risk:** vision extraction + ReAct loop are the largest single-feature builds in the inventory (14h each). Allow slippage into S4 if needed; if both done by end of S3, S4 starts early.

**Friday demo:** poster takes a photo of a broken fence → AI says "This looks like a fence repair, suggested category, estimated budget $200-350, anything else I should know?" → poster answers → publish.

### Sprint 4 — Discovery + Bidding + Public Q&A (Mon 27 Jul → Fri 7 Aug)

Mobile: home feed (ranked), vector matching consumer UI, map view of nearby tasks, list view, filters (category/budget/distance/date), sort options, saved tasks, auto-invite push handling, task share link, hide/not-interested, bid placement screen, own bids list, edit/withdraw bid, bid review (poster — list, sort, filter), accept/decline bid, public Q&A under task (replaces negotiation), bid expiry/notifications.

Backend: bid CRUD + state machine, bid notification triggers, bid expiry cron, bid validation (one active per tasker per task), vector similarity (pgvector cosine top-K), ranked feed algorithm (weighted blend), auto-invite to matched taskers, proximity calculation, category/skill matching, public Q&A backend.

**Inventory IDs:** Mobile 76-87, 88, 90-94, 96-98. Backend 261-265, 267-268, 270-273, 260.

**Friday demo:** tasker opens app → ranked feed shows tasks matched to their skills + location → taps one → places bid → poster (on second device or simulator) sees the bid arrive via push → accepts.

### Sprint 5 — Messaging + Payments core (Mon 10 Aug → Fri 21 Aug)

Mobile: inbox/thread list, conversation view (text + photo attachment + file/PDF), read receipts, report user/message, block user, off-platform warning, message search, push notifications for messages, thread freeze on dispute, add/remove card, default card, Apple/Google Pay (Stripe-managed), Stripe-hosted onboarding webview, payout history, earnings summary (tasker), transaction history (poster), receipt PDF view.

Backend: Socket.IO single-node + Redis adapter (groundwork only), message persistence, attachment upload + virus scan (local at MVP, swap for Azure Content Safety in S8), thread state machine (open/frozen), off-platform regex detection, thread freeze logic, Stripe PaymentIntent (create/capture/void), Stripe Refund (full + partial), manual capture flow ≤7d (Stripe 7-day window), SetupIntent + saved PaymentMethod for >7d / scheduled tasks, re-authorisation flow on capture expiry, payment state machine, idempotency middleware (Redis-backed), Stripe idempotency key pass-through, webhook signature verification, application fee / platform fee logic.

**Inventory IDs:** Mobile 109-112, 115, 120-125, 126-131, 132-133. Backend 274, 276, 279-281, 283-284, 286-290, 296-299, 302.

**⚠️ Stripe webhook testing.** Use `ngrok` or `cloudflared tunnel` for local Stripe webhook delivery. Zero Azure cost.

**Friday demo:** poster + tasker chat in-app → poster adds a card → places a payment hold on a task → tasker accepts → poster sees "Authorised $250" → demo the re-auth prompt by manually triggering it.

### Sprint 6 — Job execution + Completion + Tax/RCTI/GST/ATO (Mon 24 Aug → Fri 4 Sep)

Mobile: accepted-job screen, status update buttons (en route / arrived / in progress / completed), geofenced check-in / arrival proof, live location share during active job, completion proof upload (2 photos + checklist), tax invoice PDF (poster), RCTI PDF (tasker), RCTI agreement screen, refund request, re-auth prompt, promo code input, cancellation flow with fee preview.

Backend: cancellation engine with fee matrix, fee calculation logic, no-show detection (both sides), geofenced check-in verification, auto-confirm cron job, dispute window cron (48h), escalating notification cadence, state transitions for all cancel scenarios, GST calculation on platform fee, ABN status tracking + re-check cron, RCTI generation + PDF (pdfkit), RCTI agreement workflow + consent capture, tax invoice generation + PDF, ATO sharing-economy reporting export (monthly job), tax-rate config, live location share endpoint.

**Inventory IDs:** Mobile 99-105, 134-140, 142-148. Backend 285, 305-322.

**⚠️ Engage tax advisor BEFORE Sprint 6 starts.** This is the only sprint where tax-side work is on the critical path. CLAUDE.md rule 4 mandates tax advisor review before any RCTI/ATO code merges. Schedule the call by end of Sprint 5.

**Friday demo:** tasker walks into geofence (simulate) → checks in → marks complete + uploads 2 photos → auto-capture fires → tax invoice generated as PDF → tasker downloads RCTI → poster sees receipt.

### Sprint 7 — Reviews + Disputes (Tier-0 mediator + admin co-pilot) (Mon 7 Sep → Fri 18 Sep)

Mobile: post-completion review prompt (both sides), star rating, text review with min length, blind review with timeout-reveal, response to review, report review, dispute initiation flow, reason picker, evidence upload (photos + message screenshots), dispute conversation thread, AI-proposed resolution screen, accept/reject/escalate, dispute status tracker, resolution outcome screen.

Backend: review CRUD, blind review with timeout-reveal, response-to-review API, review removal API (admin-triggered), minimum-length enforcement, dispute CRUD, dispute state machine, Tier-0 LLM mediator agent (with cost guardrails — see `.claude/skills/tier0-dispute/SKILL.md`), evidence collection API, resolution proposal generation (full/partial/refund), Tier-0 threshold config (≤ AUD $200), accept/reject proposal logic, escalation to human admin, admin case brief generation (co-pilot).

**Inventory IDs:** Mobile 150-153, 155, 157, 158-166. Backend 323-325, 328-338.

**Friday demo:** poster completes task → both sides leave reviews → one party opens a dispute → AI mediator analyses thread + evidence + proof → proposes "$50 partial refund because tasker missed one item on checklist" → poster accepts → funds released accordingly.

### Sprint 8 — Notifications + Trust/Safety + Privacy (Mon 21 Sep → Fri 2 Oct)

Mobile: push (FCM/APNS) setup, in-app notification center, per-channel toggle, email opt-out (unsubscribe), SMS opt-out (STOP), notification badges, deep-link from notification, critical-state fallback, notification history (thin), DSR access/export, account deletion request.

Backend: push notification service, email service (SendGrid), SMS service (Notifyre), in-app notification queue/API, user preferences engine, notification templates, critical-state fallback escalation (push → email → SMS), Spam Act compliance, unsubscribe token endpoint, image content moderation (Azure Content Safety), async moderation queue, EXIF tampering / consistency check, rate limiting middleware, LLM cost telemetry + anomaly alerts, account suspension webhooks, data inventory + retention schema, DSR endpoints (access, delete, correct), anonymisation job (financial retained 7y), hard delete vs anonymise logic, consent ledger, PII redaction layer before external LLM calls, audit log.

**Inventory IDs:** Mobile 168-170, 172-176, 185-186. Backend 341-365.

**⚠️ Risk:** EXIF tampering + content moderation are the only places we hit Azure Content Safety. Local filesystem still works for storage; just call Content Safety from the API. Small Azure spend (~$5-15) during S8 — acceptable.

**Friday demo:** demonstrate "Privacy & Data" screen — request data export, see consent history, request deletion → backend anonymises → audit log shows the chain.

### Sprint 9 — Admin console end-to-end (Mon 5 Oct → Fri 16 Oct)

Admin: dashboard (today's queue), user list + detail, KYC review queue, Connect onboarding tracker, suspend/reinstate user, DSR request handler, task list + detail + edit/delete, content moderation queue, manual approval, force-cancel, edit AI extraction, bid list per task, public Q&A moderation queue, flagged messages queue, manual message review, thread freeze, payment list + detail, refund processing, manual capture/void, held-funds dashboard, promo code admin, tax invoice listing, RCTI status, ATO report preview/download, ATO submission log, GST rate config, dispute queue, Tier-0 suggestion panel, manual mediation, evidence viewer, resolution actions, admin notes, admin co-pilot brief renderer, review queue (flagged), manual review removal, FAQ CRUD, T&Cs versioned editor, category CRUD, sub-category CRUD, service area CRUD, platform fee config, cancellation fee matrix config, auto-confirm timing config, Tier-0 dispute threshold, manual broadcast tool, admin action audit log viewer, DSR request queue.

**Inventory IDs:** Admin 426-432, 433-437, 441-448, 450-457, 458, 460, 463, 464-468, 471-477, 480-482, 485-486, 491-494, 497-500, 507, 511, 514.

**Friday demo:** record a "day in the life of admin" — login → check today's queue → approve a KYC → resolve a dispute using Tier-0 suggestion → process a refund → export ATO report.

### Sprint 10 — DevOps + Cloud deploy + WAF (Mon 19 Oct → Fri 30 Oct)

Terraform: Azure App Service (3 apps), Azure Database for PostgreSQL Flexible (with pgvector), Azure Cache for Redis, Azure Blob Storage, Azure Key Vault, Azure Content Safety, Azure App Insights, VNet + private endpoints, NSGs. Cloudflare Pro setup: WAF rules per `docs/audit/edge-security.md`, DDoS, Bot Fight, geo-restrict admin, rate limits at edge. CI/CD: GitHub Actions pipelines (lint/test/typecheck on every PR, deploy to staging on merge to main, deploy to prod on tag), Prisma migrate deploy in CI, blob storage swap in (replace local filesystem with Azure Blob SDK calls), Key Vault references in App Service config, secrets rotation policy, encryption at rest verification, OpenAPI docs generation, health check endpoints, status page (thin).

**Inventory IDs:** Backend 403-419. Admin 501-505 (config flags). Plus `docs/audit/edge-security.md` implementation.

**Cost from this sprint onwards:** ~$300-400/mo Azure + $25/mo Cloudflare Pro. **First month with real spend.** Document burn rate weekly.

**Friday demo:** same end-to-end happy-path flow demoed in Sprint 6 — but now running on Azure staging behind Cloudflare WAF. No localhost. The client sees a public URL.

### Sprint 11 — TestFlight + bug fix + soft-launch prep (Mon 2 Nov → Fri 13 Nov)

TestFlight: Apple Developer Program enrolment if not done, signing certificates, App Store Connect setup, TestFlight internal testers (you + client + 2-3 trusted testers), upload first build. Google Play: internal testing track, signing key, upload AAB. Mobile polish: app icon final, splash, launch animation, App Store + Play Store listing screenshots, App Tracking Transparency prompt iOS. Bug fix: every issue surfaced during testing — expect 30-50 small ones in week 1. Final compliance check: re-run `security-review` skill on all code, run Semgrep + CodeQL, run `pnpm audit` for npm CVEs. Documentation pass: PROJECT_CONTEXT.md, README, contributing guide for if another dev joins. 

**Inventory IDs:** Mobile 198-205 (legal pages), 206-227 (cross-cutting), 225-227 (icons, screenshots, ATT prompt). SEO 516-521.

**Friday demo:** client installs the app on their iPhone via TestFlight invite, runs the happy path end-to-end, reports back. We file bugs and fix them next sprint.

### Sprint 12 — Soft launch + first real users + retrospective (Mon 16 Nov → Fri 27 Nov)

Soft launch logistics: pick a Sydney suburb (Newtown? Surry Hills?), onboard 30-50 taskers via manual outreach + admin invitation tool, switch Stripe from test mode to live mode (one-way decision — set a calendar reminder + checklist), monitor App Insights + Cloudflare logs daily, run a daily "what broke today" 30-min standup with yourself + client.

End-of-MVP audit: run `./scripts/coverage.sh` — every IN/IN★ row should be `done [sprint-N, PR#nn]`. Anything not done needs written justification in `docs/sprints/post-mvp-deferred.md`. Hand-off to ongoing maintenance.

Retrospective: what went well, what didn't, what's the post-MVP roadmap. Documented as `docs/sprints/retrospective.md` (committed).

**Friday demo (final):** real tasker in Sydney completes a real task posted by a real poster, with real money flowing (real test card, then real card). Both sides leave reviews. Tax invoice generated, RCTI sent. Demo recorded as the launch video.

## Tracking — how this never loses a feature

### Inventory CSV columns

| Col | Name | Role |
| --- | --- | --- |
| 1 | ID | Row identifier (referenced from PRs and sprint docs) |
| 2 | Surface | Mobile / Backend / Admin / SEO |
| 3 | Section | e.g., "1.1 Onboarding & Auth" |
| 4 | Item | The feature itself |
| 5 | Architect Note | Original gap reference from review |
| 6 | Call | IN / IN★ / THIN / POST / DROP / MANUAL |
| 7 | Hours | Estimate |
| 8 | Notes / Reason | Why this scope, why this hours estimate |
| **9** | **Your Decision** | **Used as completion marker. Set to `done [sprint-N, PR#nn]` when shipped.** |
| 10 | Your Comment | Per-row notes / commentary |

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
- [ ] All custom skills (.claude/skills/*) reviewed for currency
- [ ] CI pipelines all green on `main` for last 7 days
- [ ] Pen test booked for post-launch (within 60 days)

## Open decisions — must be resolved before the sprint that depends on them

| Decision | Needed before | Default if not decided | ADR home |
| --- | --- | --- | --- |
| KYC vendor: Didit / manual review | Day 1 of Sprint 2 (29 Jun) | Manual review queue | `docs/adrs/005-kyc-strategy.md` |
| Auth token storage: HttpOnly cookie / Bearer header (per surface) | Day 1 of Sprint 1 (15 Jun) | Bearer for mobile, HttpOnly for web/admin | `docs/adrs/006-auth-tokens.md` |
| Edge security vendor: Cloudflare Pro / Azure Front Door Premium | Mid Sprint 9 (so it's procured before Sprint 10) | Cloudflare Pro ($25/mo) | `docs/adrs/007-edge-security.md` |
| Tax advisor engagement | Mid Sprint 5 (so they're available for Sprint 6 reviews) | Engage anyway | n/a |
| Apple Developer Program enrolment | Mid Sprint 10 (so TestFlight is ready for Sprint 11) | Enrol anyway ($99/yr) | n/a |

## Risk register

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| AI extraction quality below acceptable | Medium | High | Sprint 3 includes evaluation harness; budget +20h buffer in S3-S4 for prompt iteration |
| Stripe Connect setup blocks on AU compliance review by Stripe | Low | High | Initiate Stripe Connect onboarding application in Sprint 1 — review takes 5-10 business days |
| Didit unavailable / suddenly changes pricing | Low | Medium | Manual KYC path is the fallback; we've already designed both — ADR documents the choice |
| Vision model cost spike (vision is ~10× text cost) | Medium | Medium | Cost guardrails enforced via `.claude/skills/multimodal-extraction/SKILL.md`; daily cost cap per user + global |
| Mobile push notifications break on real iOS (sim is forgiving) | Medium | Medium | Sprint 11 TestFlight catches this; budget time in S11 to debug APNS |
| End-of-MVP soft launch reveals a P0 we missed | High | Medium | Sprints 11-12 ARE the buffer. Don't over-commit them. |
| Tax/RCTI/ATO interpretation differs from tax advisor | Medium | Critical | Engage advisor BEFORE Sprint 6 starts (mid-S5). Don't merge without sign-off. |
| Auto-updater bumps a critical dep mid-sprint | Low (now) | High | `.github/dependabot.yml` configured for monthly + minor/patch only; majors require manual ADR |

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
- `sprint-01-onboarding-and-auth.md` — Sprint 1 detail
- `sprint-02-kyc-and-tasker.md` — created end of Sprint 1
- `sprint-03-task-posting-and-ai.md` — created end of Sprint 2
- ...etc

Each sprint doc includes: inventory IDs in scope, definition of done per feature, demo script for Friday, risk + decision callouts, link to the PRs that landed.

## References

- `PROJECT_CONTEXT.md` — full architectural context
- `CLAUDE.md` — hard rules (CLAUDE.md rule 2 = manual review of payment/tax/PII, etc.)
- `docs/adrs/` — architecture decisions
- `docs/audit/` — IT audit documentation
- `inventory/JOBBees_Feature_Inventory.csv` — 522-row feature list (gitignored)
- `scripts/coverage.sh` — Friday coverage report
