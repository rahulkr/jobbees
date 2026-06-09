# JOBBees — Project Context Brief

> **Hand this document to any AI assistant at the start of a coding session and it will have full project context without needing to read companion docs first.** This is the single source of truth for architecture, conventions, and technical decisions.

---

## 1. What is JOBBees?

JOBBees is an **Australian peer-to-peer task marketplace** (think Airtasker / hipages / Oneflare for the AU market). Posters post tasks ("clean my gutters", "move a couch", "fix a leaky tap"), taskers bid on them, the platform handles payments via Stripe Connect, and the marketplace takes a fee per transaction.

The product is mobile-first (Flutter for iOS + Android), with a Next.js admin console for internal operations and a minimal Next.js public web layer for SEO. All clients talk to a single Node.js backend (NestJS).

Differentiating bets for v1: vector-based matching, ranked discovery feed, autonomous Tier-0 dispute triage, and voice-driven task posting. The first three are AI-native marketplace features delivered at launch.

---

## 2. Project Scope

- **Market:** Australia only at MVP
- **Languages:** English only at MVP
- **Platforms:** iOS + Android (Flutter), Web for admin + SEO only
- **AI dev tooling:** Encouraged — Claude Code is the primary assistant; CLAUDE.md files at root and in each app load relevant context automatically

---

## 3. Tech Stack — Decisions, Not Options

Every choice locked in. Do not re-litigate without an ADR.

| Layer | Choice | Why |
| --- | --- | --- |
| **Backend language** | Node.js + TypeScript | Strong AI codegen support, mature ecosystem, shared types with web clients |
| **Backend framework** | NestJS | Opinionated structure prevents drift over time; modules map 1:1 to product domains; strong AI-codegen patterns |
| **ORM** | Prisma | Schema-as-code, type safety, free migrations, less AI hallucination than raw SQL |
| **Database** | PostgreSQL 16 + pgvector | Single DB for relational + vector; no separate vector store |
| **Cache / queue** | Redis | Sessions, rate limits, idempotency, BullMQ jobs |
| **Job queue** | BullMQ on Redis | Native Node, no separate Azure Service Bus needed at MVP |
| **Real-time** | Socket.IO (single-node at MVP) | Sufficient for <3k concurrent; Redis adapter post-launch |
| **Mobile** | Flutter (iOS + Android) | Single codebase, both stores |
| **Mobile state mgmt** | Riverpod | Cleanest async story, great AI codegen support |
| **Mobile navigation** | go_router | Standard for Flutter |
| **Mobile HTTP** | dio | Standard for Flutter |
| **Admin + Public web** | Next.js 14 (App Router) | One framework for both UIs, share components |
| **UI components (web)** | shadcn/ui + Tailwind | We own the component code, AI can modify freely |
| **Auth** | Custom JWT + Postgres (no Auth0/Clerk) | AU data residency simpler, no vendor lock |
| **Phone OTP** | Firebase Phone Auth OR Twilio Verify (TBD by branded-sender requirement) | Firebase is cheaper; Twilio supports a branded "JOBBEES" alpha sender |
| **Payments** | Stripe + Stripe Connect Express + Stripe Identity | One vendor for the whole flow |
| **LLM (high-volume)** | Google Gemini 2.0 Flash | Cheapest at scale; primary model |
| **LLM (nuanced)** | Anthropic Claude Sonnet | Disputes, admin co-pilot |
| **Embeddings** | OpenAI text-embedding-3-small | 1536 dims; small, fast, cheap |
| **Push notifications** | FCM (Android) + APNS (iOS) | Free, standard |
| **SMS** | Twilio (alternative: Telnyx) | Pending Azure Communication Services check |
| **Email** | SendGrid (alternative: AWS SES) | Pending Azure Communication Services check |
| **Image moderation** | Azure Content Safety | AU region available |
| **Geocoding** | Mapbox or Google Maps | TBD by cost |
| **Error tracking** | Sentry | Portable across clouds |
| **Logs + APM** | Azure Application Insights | May swap to OpenTelemetry-based later |
| **Hosting** | Azure (full stack) | Client preference; portability planned via Terraform |
| **CI/CD** | GitHub Actions | Portable, not Azure DevOps |
| **IaC** | Terraform (chosen over Bicep) | Multi-cloud future |
| **Monorepo tooling** | pnpm workspaces + Turborepo | Standard for TS monorepos |
| **Analytics** | PostHog or Mixpanel | TBD; THIN scope at MVP |

---

## 4. Repo Layout

Single monorepo, single git repository.

```
jobbees/
├── CLAUDE.md                # global project rules + pointer to this file
├── PROJECT_CONTEXT.md       # this file
├── README.md                # onboarding for human readers
├── .claude/
│   ├── settings.json        # tool allowlist, MCP servers
│   ├── commands/            # custom slash commands
│   └── skills/              # custom skills (see §15)
├── apps/
│   ├── mobile/              # Flutter (iOS + Android)
│   │   └── CLAUDE.md
│   ├── api/                 # NestJS backend (single source of truth for business logic)
│   │   └── CLAUDE.md
│   ├── admin/               # Next.js admin console
│   │   └── CLAUDE.md
│   └── web/                 # Next.js public/SEO pages
│       └── CLAUDE.md
├── packages/
│   ├── types/               # TS types generated from NestJS OpenAPI spec
│   ├── prisma/              # schema.prisma + migrations
│   ├── eslint-config/       # shared ESLint config
│   └── tsconfig/            # shared tsconfig bases
├── docs/
│   ├── adrs/                # Architecture Decision Records (numbered: 001, 002, ...)
│   ├── audit/               # IT audit documentation (see §18)
│   └── runbooks/            # operational procedures
├── ops/
│   ├── docker/              # Docker Compose for local Postgres + Redis
│   └── terraform/           # Azure infrastructure-as-code (post-MVP)
```

Note: an `inventory/` folder may exist locally (gitignored) — it holds the internal scoping and planning docs and isn't part of the committed repo.

---

## 5. The Four Surfaces

Three clients, one backend. Next.js (admin + web) and Flutter (mobile) are all *clients* of the NestJS API — they do not contain business logic.

**`apps/api/` (NestJS) — the real backend.**
All business logic, Stripe, Prisma/Postgres, BullMQ, Socket.IO, LLM calls, embeddings. Exposes REST endpoints + WebSocket for messaging and live location. NestJS feature-module pattern: one module per domain (auth, users, tasks, bids, payments, tax, cancellation, reviews, disputes, notifications, trust-safety, privacy, ai, admin).

**`apps/mobile/` (Flutter) — user-facing app.**
Both poster and tasker flows. Feature-first folders: `features/<name>/{screens, widgets, providers, models}`. Riverpod for state. Calls the NestJS API.

**`apps/admin/` (Next.js) — internal operations.**
Manual-heavy by design. KYC queue, dispute mediator UI, payment refunds, RCTI status, content moderation, FAQ CRUD. Server Components by default, `'use client'` only when needed for interactivity. Calls the NestJS API (no direct DB access).

**`apps/web/` (Next.js) — public + SEO.**
Single landing page + task detail public pages for SEO. Server-rendered. Reads from NestJS API.

---

## 6. Architecture Principles

1. **Monorepo, single git repo.** Cross-surface visibility for AI coding.
2. **One backend, three clients.** Business logic lives only in `apps/api`. Never in Next.js Server Actions or Flutter.
3. **API contract is the source of truth.** NestJS exposes OpenAPI; `packages/types` is generated from it; admin + web consume it. Dart types for Flutter generated from same source.
4. **Single Postgres + pgvector.** No separate vector store. No microservices at MVP.
5. **Single-node Socket.IO at MVP.** Redis adapter for horizontal scale deferred until volume justifies it.
6. **Idempotency on every mutating endpoint.** Required header, Redis-backed cache with 24h TTL.
7. **All money in cents (integer).** Never `Decimal`, never `Float`.
8. **UTC in DB, Australia/Sydney in UI.** Never store local time.
9. **Soft delete on user-facing entities** (`deletedAt`). Hard delete on ephemeral (OTPs, sessions, idempotency keys).
10. **PII redacted before any external LLM call.** No raw user content sent to Gemini/Anthropic.
11. **Per-user rate limits on AI endpoints.** Cost telemetry with anomaly alerts.
12. **Multi-country schema-ready** (see §10). All amounts and compliance tables have `countryCode`, default `"AU"`.
13. **Category type field** (TRANSACTIONAL / LEAD). All MVP categories TRANSACTIONAL; LEAD path post-MVP (see §11).

---

## 7. Client-Locked Features (must ship in MVP)

These four are non-negotiable per direct client direction. Tagged `IN★` in the feature inventory.

**1. Vector-based matching.**
On every task publish, generate embedding (OpenAI text-embedding-3-small, 1536 dims) from title + description + skills. Store in `pgvector` column on Task. Same for tasker profiles (bio + skills + completed-job history). When a tasker opens the home feed, query top-K semantically matched tasks using cosine similarity, combined with proximity and category filters.

**2. Ranked feed.**
Replaces map-only browse. Deterministic weighted blend: vector similarity × distance × category fit × recency × budget alignment. Hand-tuned weights, config-driven (admin can adjust). LightGBM ranker deferred post-launch when there's training data.

**3. Autonomous dispute triage (Tier-0).**
When a dispute opens, if the disputed amount is ≤ AUD $200, an LLM agent (Claude Sonnet) reads the full thread + evidence + completion proof and proposes a resolution: full release / partial release / refund. Either party accepts → resolved. Either party escalates → admin handles with the help of an admin co-pilot brief (also LLM-generated: timeline, key messages highlighted, evidence summary, precedent from similar past disputes, recommended action with confidence score).

**4. Voice-driven task posting.**
Poster taps mic, speaks task description ("Need someone to mow my lawn this Saturday afternoon, around sixty dollars"). Speech-to-text via Gemini audio or Whisper-equivalent. Transcript fed into the AI extraction pipeline. Poster confirms parsed fields before publish.

---

## 8. Compliance Non-Negotiables (Australian)

These cannot be skipped or deferred without legal exposure. All `IN` in the inventory.

**Tax:**
- ABN collection at tasker signup with ABR (Australian Business Register) lookup
- GST calculation on the platform fee (confirm with tax advisor; not on full task amount)
- RCTI (Recipient-Created Tax Invoice) generation for taskers without ABN, with consent workflow
- Tax invoice PDFs to both sides on every transaction
- Monthly ATO sharing-economy reporting export with all mandatory fields
- Engage tax advisor in week 1, sign-off before payment code merges

**Stripe payments:**
- Stripe Connect Express onboarding as a separate flow from KYC. Bidding allowed after KYC; first payout gated on Connect completion.
- Held funds banner + reminder cadence (24h / 72h / 7d) until Connect complete
- Manual capture for tasks ≤7 days
- **SetupIntent + saved PaymentMethod for tasks >7 days** (because Stripe authorisation expires after 7 days)
- **Re-authorisation flow** when capture is approaching expiry on a long-running task
- Partial refund supported. Partial capture is NOT.
- Idempotency on every mutating endpoint
- Stripe idempotency key pass-through
- Full payment state machine: `authorised`, `captured`, `re-auth-required`, `setup-only`, `failed`, `voided`, `refunded`, `partial-refunded`

**Privacy Act:**
- Data inventory + retention schema per table
- DSR (Data Subject Request) endpoints: access, delete, correct
- Anonymisation pipeline: replace PII with `[deleted-user-{uuid}]`, retain financial records 7 years per ATO
- Consent ledger: versioned consent records
- PII redaction before external LLM calls
- Privacy policy authored by Australian counsel matches system behaviour

**Trust safety:**
- Mandatory tasker completion proof (2 photos + checklist) before auto-confirm
- 48-hour dispute window after completion proof submitted
- Escalating notification cadence: at submission, 24h, 36h, 12h pre-expiry
- Image content moderation (Azure Content Safety) on every upload
- Real-time per-message chat policing classifier (Gemini Flash)
- EXIF tampering check on completion-proof and task photos

**Spam Act:**
- Granular per-channel opt-out (push / email / SMS)
- Unsubscribe token endpoint on every marketing email
- SMS STOP keyword honoured

---

## 9. Database Conventions

Lock these in the first Prisma migration. Painful to retrofit.

**IDs:** Use `cuid2` (via `@paralleldrive/cuid2`) for all primary keys. URL-safe, sortable, no row-count leakage. Set in app code, not DB default.

**Money:** Integer cents (`amountCents Int`), never `Decimal`/`Float`. Format for display only.

**Time:** Store everything as `timestamptz` (Prisma `DateTime`). UTC always. Render in `Australia/Sydney` in UI.

**Timestamps:** Every table has `createdAt` (`@default(now())`) and `updatedAt` (`@updatedAt`).

**Soft delete:** User-facing entities (User, Task, Bid, Review, Thread) have `deletedAt DateTime?`. Wrap a Prisma extension to filter `where: { deletedAt: null }` by default. Hard delete for ephemeral tables (OTPs, sessions, idempotency keys, drafts never published).

**Enums:** Use Prisma enums for all state machines (TaskStatus, BidStatus, PaymentState, DisputeState, CategoryType, etc.). Never strings.

**Foreign keys:** Always declare with explicit `onDelete` behaviour (`Cascade`, `Restrict`, `SetNull`, `NoAction`). Decide per FK.

**Indexes on foreign keys:** Prisma does NOT auto-index FKs. Add `@@index([userId])`, `@@index([taskId])` etc. manually. Without these, joins go to sequential scans at scale.

**JSONB:** Use for opaque metadata only (e.g., `Task.extractedFields`). Never for things you `WHERE` on — model those as real columns.

**Audit log table:** Append-only. Schema: `id, actorId, action, resourceType, resourceId, diffJson, ipAddress, userAgent, createdAt`. Every sensitive write (suspension, refund, KYC override, dispute resolution) writes one row. Index `(resourceType, resourceId, createdAt)`.

**Anonymisation:** When a user requests deletion, replace name/email/phone/address with `[deleted-user-{uuid}]` or NULL, keep payments + tax invoices + RCTI records intact for 7 years per ATO, set `deletedAt` and `anonymisedAt`.

**Vector columns:** Use `Unsupported("vector(1536)")` in Prisma schema (Prisma doesn't natively understand the type). Query via `$queryRaw` for cosine similarity. Index with HNSW (not IVFFlat).

---

## 10. Multi-Country Readiness

Schema is country-aware; logic is AU-only at MVP. ADR: `docs/adrs/003-multi-country-readiness.md`.

```prisma
model Country {
  code         String  @id  // ISO 3166-1 alpha-2: "AU", "NZ"
  name         String
  currencyCode String        // "AUD", "NZD"
  defaultLocale String        // "en-AU"
  taxModel     String        // "AU_GST_RCTI_ATO", "NZ_GST", etc.
  phonePrefix  String        // "+61", "+64"
  isActive     Boolean @default(false)
}

model User       { countryCode String @default("AU") }
model Task       { countryCode String @default("AU") }
model Payment    { countryCode String @default("AU") }
model TaxInvoice { countryCode String @default("AU") }
```

In MVP: hardcode `"AU"` everywhere. Don't build country selector UI. Don't write NZ tax logic. When NZ is added later, it's an entry in the Country table + a new tax module — no schema migration on every table.

---

## 11. Category Type System

```prisma
enum CategoryType {
  TRANSACTIONAL  // payment flows through platform (default; only type at MVP)
  LEAD           // poster→tasker intro, payment off-platform (post-MVP)
}

model Category {
  id            String       @id
  name          String
  type          CategoryType @default(TRANSACTIONAL)
  leadFeeCents  Int?         // only used if type = LEAD
  // ...
}

model Task {
  // ...
  transactionType CategoryType  // snapshot from Category at creation; immutable per task
}
```

In MVP code:
- Payment, dispute, RCTI, cancellation services assert `task.transactionType === 'TRANSACTIONAL'` and throw if not
- LEAD flow doesn't exist yet — it's documented as post-MVP work

When LEAD categories arrive: new payment flow (tasker pays lead fee to unlock contact), no escrow, no RCTI, different review trigger. ADR: `docs/adrs/004-category-types.md`.

---

## 12. Payment Architecture Summary

**Stripe products used:**
- PaymentIntent (manual capture for ≤7d tasks)
- SetupIntent (saved PaymentMethod for >7d / scheduled-future tasks)
- Refund (full + partial supported)
- Connect Express (tasker payouts; KYC/identity bundled)
- Stripe Identity (separate KYC for posters and bidders)

**State machine:**
```
authorised → captured        // happy path, ≤7d task
authorised → re-auth-required → authorised  // long task crossing 7d
setup-only → captured        // scheduled-future task; PM stored, charged at completion
authorised → voided          // cancelled before capture
captured → refunded          // full refund
captured → partial-refunded  // partial refund
authorised → failed          // card declined at capture
```

**Idempotency:**
Required `Idempotency-Key` header on every mutating endpoint. Redis-backed cache with 24h TTL. Same key on retry returns the cached response. Pass through to Stripe SDK for double-protection.

**Promo codes:**
Engine supports CRUD, single-use vs multi-use, expiry, applied at PaymentIntent creation, audit log.

**Application fee:**
Platform fee config per category, GST calculated on the platform fee (not the full task amount).

---

## 13. AI Usage

**Where AI is used per task lifecycle:**

| Touchpoint | Model |
| --- | --- |
| Task extraction (text → structured fields) | Gemini Flash |
| Multi-turn clarifying questions (when confidence is low) | Gemini Flash |
| Multimodal image extraction (when poster uploads photos) | Gemini 1.5 Pro vision |
| Voice transcription | Gemini audio / Whisper |
| Budget AI nudge | Gemini Flash |
| Task + tasker profile embeddings | OpenAI text-embedding-3-small (1536 dims) |
| Real-time per-message chat policing | Gemini Flash |
| EXIF tampering check (deterministic, no LLM) | n/a |
| Tier-0 dispute mediator | Claude Sonnet |
| Admin co-pilot brief | Claude Sonnet |
| RAG support agent | Gemini Flash |

**Cost controls in code:**

1. Per-user rate limits on every AI endpoint
2. LLM cost telemetry with alerts on anomalies (e.g., daily spend exceeds 1.5× rolling median)
3. PII redaction layer before any external LLM call
4. Thin LLM-provider interface — direct provider (Gemini or Anthropic) with zero-retention enabled for sensitive paths (messages, disputes, PII)
5. Default model selection: route to Flash/Haiku unless there's a reason to use Sonnet

---

## 15. CLAUDE.md Hierarchy

Claude Code auto-loads CLAUDE.md from the working directory upward. Place context where it's relevant. Keep each file short (~80 lines).

**Root `CLAUDE.md`:**
- One-line project description
- Tech stack list (one line each)
- Hard rules: never commit secrets, all payment code requires manual review, GST/RCTI/ATO is non-negotiable
- Pointer to this file (`PROJECT_CONTEXT.md`)
- Pointer to your scope tracker / issue board as the source of work items

**`apps/api/CLAUDE.md`:**
- "NestJS feature-module pattern, one module per domain"
- "Every mutating endpoint requires idempotency middleware"
- "All Stripe calls go through `StripeService` wrapper, never SDK directly from controllers"
- "Postgres + Prisma; pgvector for embeddings; raw SQL via `$queryRaw` only for vector searches and analytical queries"
- "Structured JSON logs to App Insights, never `console.log`"

**`apps/mobile/CLAUDE.md`:**
- "Riverpod for state, go_router for navigation, dio for HTTP"
- "Feature-first folders: `features/<name>/{screens, widgets, providers, models}`"
- "Every screen has: loading state, error state, empty state, content"
- "Never hardcode colours; use `Theme.of(context).colorScheme.x` — theme-ready architecture"
- "Payment UI uses official Stripe Flutter SDK, not custom Elements"

**`apps/admin/CLAUDE.md`:**
- "Next.js 14 App Router, shadcn/ui + Tailwind"
- "Server Components by default; `'use client'` only when interactivity needed"
- "Admin actions call NestJS API via fetch; never touch DB directly"

**`apps/web/CLAUDE.md`:**
- "Same Next.js stack as admin"
- "Public read-only; no auth-gated content"
- "Server-render task detail pages for SEO"

---

## 16. Custom Claude Code Skills

Install in `.claude/skills/`. Each is a folder with a `SKILL.md`.

**1. `stripe-payment`** — invoked when touching payments. Contains: full payment state machine, capture window rules, idempotency conventions, refund logic, RCTI trigger points, SetupIntent vs PaymentIntent decision tree.

**2. `au-tax`** — invoked when touching tax/RCTI/ATO/GST. Contains: GST calculation rules (platform fee only), RCTI agreement workflow, ATO export field schema, ABN/ABR rules. **High-risk area for AI hallucination — always manually review LLM output here.**

**3. `pgvector-match`** — invoked for matching/ranking work. Contains: embedding model choice, cosine query patterns, top-K with filters, ranked-feed weighted blend, vector + deterministic signal combination.

**4. `tier0-dispute`** — invoked for dispute mediator work. Contains: system prompt, evidence aggregation pattern, output schema, threshold rules, when to escalate.

**5. `multimodal-extraction`** — invoked for image-to-task vision extraction. Contains: model tier selection (Flash primary, Pro fallback — never Opus), image preprocessing pipeline (resize/EXIF/hash), Zod schema, prompt structure, merging with text extraction, cost guardrails.

**Built-in skills also enabled:**
- `security-review` — run against every PR touching auth/payments/PII
- `review` — general code review
- `skill-creator` — for adding new skills later

---

## 17. Workflow with Claude Code (or any AI)

**Daily flow:**
1. Pick 1–3 work items from your scope tracker / issue board. Mark them in-progress.
2. Open Claude Code in the repo. CLAUDE.md files auto-load.
3. Paste the work item summary as the spec (e.g. "Mobile · Task Discovery · Home feed (ranked) · MVP-IN").
4. Enter **plan mode** (Shift+Tab in CLI, or `/plan`) for anything above ~30 minutes of work. Review the plan before code is written.
5. Branch naming: `feat/<short-name>` (e.g., `feat/ranked-feed`).
6. Conventional Commit messages: `feat: ranked feed v0 — deterministic blend`.
7. Run tests as you go (`pnpm test` for backend, Flutter widget tests for mobile).
8. Open a PR for every change — the diff view forces a final review.
9. Mark the work item DONE when merged.

**End of week:**
- Review what shipped versus what's still in progress.
- Triage any items that grew in scope into their own follow-up tickets.

**Plan mode discipline:** for any task that's not "rename a variable", always plan first. Catches hallucinations and saves hours of rework.

---

## 18. Security Tooling

Layered. Each gate catches different things.

**Pre-commit (local, <5 sec):**
- `lefthook` — hooks runner (configured in `lefthook.yml`)
- `gitleaks` — blocks commits containing secrets
- `eslint` + `eslint-plugin-security` — catches common JS/TS security smells
- `prettier` — consistent formatting

**Every PR (GitHub Actions, 2–5 min):**
- CodeQL — SAST scanner (free with GH Advanced Security)
- Dependabot — auto-PRs for vulnerable dependencies
- Semgrep — rule-based SAST with NestJS/Flutter rule packs
- gitleaks — secrets detection in CI (belt + braces with pre-commit)
- Trivy — Docker image, dependency, and IaC scanning

**Runtime / edge (always-on, in front of the API) — vendor TBD per client decision:**
- **Option A (recommended for MVP):** Cloudflare Pro ($25/mo) — OWASP managed rules, Bot Fight Mode, DDoS, geo-restriction, rate limits at edge. App Service IP-restricted to Cloudflare ranges.
- **Option B:** Azure Front Door Premium + WAF ($335/mo) — same protections plus ML-based Bot Manager, private link to App Service (zero public IPs on backend).
- **Common to both:** VNet + private endpoints for Postgres / Redis / Blob / Key Vault (no public IPs on data stores)
- **DDoS:** L3/L7 included in both options; Azure DDoS Standard ($2,900/mo) is overkill at MVP
- See `docs/audit/edge-security.md` for the full decision framework and custom rules

**Weekly / on-demand:**
- OWASP ZAP — dynamic scan (DAST) against staging
- `pnpm audit` + `flutter pub outdated` — manual dependency sanity check

**Quarterly:**
- External pen-test (client-side)
- Secrets rotation per `docs/audit/encryption-policy.md` rotation table

**On every PR touching auth/payments/PII:**
- Run the `security-review` skill in Claude Code before merging

---

## 19. IT Audit Documentation

Scaffolded as templates in `docs/audit/`. Fill as features ship.

```
docs/audit/
├── architecture-overview.md       # one-pager system diagram
├── data-flow-diagram.md           # PII paths, payment paths
├── data-classification-policy.md  # what counts as PII / Financial / Operational
├── data-retention-policy.md       # per-table retention rules
├── encryption-policy.md           # at-rest, in-transit, secret management
├── access-control-policy.md       # who can access what
├── backup-recovery-procedure.md   # daily backups, PIT restore, quarterly drill
├── incident-response-plan.md      # what happens during a security incident
├── vulnerability-management.md    # the security tooling setup
├── change-management.md           # git workflow, branch protection, PR review
├── vendor-list.md                 # Stripe, Gemini, Twilio, etc. with DPAs linked
├── privacy-policy.md              # customer-facing
├── dsr-process.md                 # how DSR requests are handled
├── audit-log-policy.md            # what gets logged, retention, access
├── bcp-dr-plan.md                 # RTO/RPO targets
├── secure-sdlc.md                 # how code goes dev → staging → prod
└── australian-compliance.md       # GST/RCTI/ATO/Privacy Act mapping
```

---

## 20. What's Cut, What's Deferred, What's Manual

To keep MVP scope tight, certain items are explicitly deferred. Don't accidentally rebuild what's deferred.

**DROP (don't build at all):**
- Magic link login
- Welcome tour / coach marks
- Tasker availability calendar + API
- Recurring task posting
- Counter-offer / negotiation in-thread (replaced with public Q&A on task)
- In-app voice/video call
- Job extension / reschedule
- Message reactions, voice messages, typing indicators, mute/archive/pin threads
- Wallet / store credit
- Per-category notification prefs
- Referral / invite friend
- Right-to-left text support
- Admin impersonation
- Bulk operations in admin
- Merge duplicate accounts
- Tasker public profile page (SEO)
- Category landing pages (SEO)

**POST (deferred, may revisit at month 3+):**
- SEO content auto-generation per task
- Bid AI coaching nudges (needs real bid acceptance data first)
- Review authenticity scoring (needs review data first)
- Behavioural fraud detection (graph-based)
- LightGBM ranker (deterministic weights at MVP)
- Webhook DLQ + replay tool
- Partial captures / milestone billing
- 2FA for users (admin has 2FA at MVP)
- Notification preference centre (granular per-category)
- Language switcher (English only at MVP)
- A/B testing SDK (env flag booleans only)
- Mobile offline behaviour (drafts only at MVP, no full offline)
- Multi-region failover, 99.9% SLO (99.5% accepted at MVP)
- Load testing, DR drills

**Promoted from POST → IN this round:**
- Multi-turn clarifying ReAct loop (multi-turn dialogue when AI confidence is low on required fields)
- Multimodal image-based task extraction (vision model infers scope/materials/duration from photos)
- EXIF tampering / consistency check (detect tasker uploading old/wrong-location photos as completion proof)

**MANUAL (operator-driven via admin or external tool):**
- Auto-invite broadcast on cold-start (admin pushes manually)
- Connect onboarding nudges (admin contacts stuck taskers)
- Synthetic supply seeding (hand-onboard first 50 taskers per geography)
- Inbound support (shared inbox, no ticket queue at MVP)
- Reconciliation / accounting (external tool — Xero etc.)
- Pen-test, accessibility audit, full QA cycle (client-side)

---

## 21. Open Decisions (need client sign-off before relevant code)

1. **Cancellation fee matrix** — proposed two-tier: free up to 24h, 100% under 24h. Client legal review.
2. **Auto-confirm dispute window** — proposed 48h.
3. **Tier-0 dispute threshold** — proposed AUD $200.
4. **Connect Express vs Connect Standard** — Express assumed.
5. **GST architecture** — confirm platform-fee-only with tax advisor before payment code.
6. **RCTI workflow + agreement copy** — drafted by tax advisor + legal.
7. **Privacy retention policy per table** — client + counsel sign-off.
8. **SMS provider** — Twilio assumed, awaiting Azure expert review.
9. **Email provider** — SendGrid assumed, same.
10. **Phone OTP** — Firebase Phone Auth (cheap, no branded sender) vs Twilio Verify (~$5/month, branded "JOBBEES" sender). Awaiting decision.
11. **LLM data-residency** — direct providers (Gemini, Anthropic) with zero-retention for sensitive paths; OpenRouter OK for non-sensitive.
12. **Linked accounts management UI** — keep THIN (2 hrs) or DROP?
13. **Branding assets (icon, splash, colours)** — client-supplied.
14. **App Store + Play Store account ownership** — client.
15. **Stripe AU entity + Connect platform account** — client.

---

## 22. First-Week Checklist (when starting code)

1. `git init`, monorepo skeleton, pnpm workspaces, Turborepo, root `CLAUDE.md`, root `PROJECT_CONTEXT.md` ✅ DONE in scaffold
2. Postgres 16 + pgvector + Redis 7 via Docker Compose (`ops/docker/dev.yml`) ✅ DONE
3. NestJS scaffold in `apps/api`; Prisma schema with `User` + `Country` + `Category` + `Task` + `AuditLog` ✅ DONE
4. Flutter scaffold in `apps/mobile`; Riverpod + go_router + dio — **run `flutter create .` first**
5. Next.js scaffold in `apps/admin` with shadcn/ui — **run `pnpm create next-app@latest` first**
6. Next.js scaffold in `apps/web` — same
7. The 5 custom skills (`stripe-payment`, `au-tax`, `pgvector-match`, `tier0-dispute`, `multimodal-extraction`) ✅ DONE as stubs
8. `.claude/settings.json` with tool allowlist ✅ DONE; **install Postgres MCP manually**
9. First ADR: `docs/adrs/001-monorepo-and-stack.md` ✅ DONE
10. `docs/audit/` folder scaffolded with 17 templates ✅ DONE
11. GitHub Actions CI: `pnpm lint` + `pnpm test` on PR — **add `.github/workflows/ci.yml` when scaffolds exist**
12. Commit + push to GitHub. Branch protection on `main`.

---

## 23. Pitfalls to Avoid

- **Never accept AI-written GST/RCTI/ATO/payment code without manual review.** This is the biggest blast-radius area.
- **Never commit secrets.** Pre-commit gitleaks catches most; CI catches the rest.
- **Never auto-migrate in prod startup.** Only CI runs `prisma migrate deploy`.
- **Never edit a migration after it's merged to main.** Always write a new migration.
- **Never trust AI on time zones.** Hard-code `Australia/Sydney` everywhere until proven otherwise.
- **Never put DB credentials in `.env.production` on disk.** Key Vault → App Service env vars → process.
- **Never skip foreign-key indexes.** Prisma doesn't auto-add them.
- **Never use `$executeRaw` with string interpolation.** Always parameterised template-tag form.
- **Never let the LLM see raw user PII.** Redact through the layer first.
- **Never pre-optimise the stack** — no GraphQL, no microservices, no Kubernetes, no event sourcing at MVP.

---

## 24. Reference Files in the Repo

| File | Purpose |
| --- | --- |
| `PROJECT_CONTEXT.md` (this file) | Master context — load first |
| `CLAUDE.md` (root) | Short rules — auto-loaded by Claude Code |
| `apps/*/CLAUDE.md` | Surface-specific rules |
| `inventory/` (local, gitignored) | Internal scoping + planning docs (not committed) |
| `docs/adrs/` | ADRs as they're written |
| `docs/audit/` | IT audit documentation templates |
| `packages/prisma/schema.prisma` | Database schema source of truth |
| `ops/docker/dev.yml` | Local Postgres + Redis |
| `.claude/skills/` | Custom Claude Code skills |
| `lefthook.yml` | Pre-commit + pre-push hook config |
| `.env.example` | All environment variables documented |

---

## 25. End-of-Brief Checklist for the AI

Before starting any work, the AI assistant should confirm:

1. [ ] I have read this file in full.
2. [ ] I have identified which work item I'm working on.
3. [ ] I have read the relevant `apps/<surface>/CLAUDE.md`.
4. [ ] If this work touches payments / tax / PII, I will manually review my code and run the `security-review` skill before merging.
5. [ ] I am respecting the scope tier of the work item (e.g. MVP-IN / THIN / DEFERRED). I will not silently expand scope.
6. [ ] I will use Plan Mode for anything above ~30 minutes of work.
7. [ ] I will write tests as I go.
8. [ ] I will use a Conventional Commit message (`feat:`, `fix:`, `chore:`).
9. [ ] If I introduce a new pattern, I will document it in a CLAUDE.md or ADR.
10. [ ] If anything in this brief contradicts what I'm being asked to do, I will pause and flag the conflict — not silently override.

---

*End of project context brief. Begin coding.*
