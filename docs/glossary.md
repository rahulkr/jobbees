# JOBBees Glossary

One-line definitions for every domain term in the project. When the AI (or a new contributor) sees an unfamiliar word, look here first.

Organised by category. Terms are bolded so you can grep.

---

## User roles

- **Client** — A user who posts jobs. Pays for work. Schema: `UserRole.CLIENT`. Previously called "Poster" (renamed to avoid Airtasker trademark overlap).
- **Tasker** — A user who completes jobs. Gets paid. Schema: `UserRole.TASKER`.
- **Admin** — Platform staff with operational privileges. Schema: `UserRole.ADMIN`.
- **Super Admin** — Founder + senior staff with destructive privileges (refunds > $1k, hard delete, bulk ops). Schema: `UserRole.SUPER_ADMIN`. Required for two-person approval (AP-56).
- **FSE** — Field Sales Executive. Admin-portal user with scoped access to verification queue + their referred tasker list. Replaces the separate FSE app (deferred to V2).

## Marketplace primitives

- **Job** — A unit of work a Client wants done. Schema: `Job`. Previously called "Task" (renamed to avoid Airtasker overlap).
- **Offer** — A Tasker's bid on a Job. Schema: `Offer`. Previously called "Bid."
- **Category** — Service classification (Cleaning, Plumbing, Electrical, etc.). Some require licences (per ADR 005).
- **Service area** — Suburb + radius a Tasker serves. Hard filter in the matching engine.
- **Trust score** — Computed reputation per Tasker. Inputs: rating, completion rate, response time, dispute history. Recomputed on each review reveal.

## Identity & verification (ADR 005)

- **KYC** — Know Your Customer. Identity verification. JOBBees delegates to Stripe Connect — no manual ID queue.
- **Stripe Connect Express** — Stripe's hosted onboarding flow that handles identity verification end-to-end on Stripe's side. We mirror the status, never store the documents.
- **ABN** — Australian Business Number. 11-digit identifier for businesses. Required for Taskers who want to issue their own tax invoices.
- **ABR** — Australian Business Register. Free public API to validate an ABN + retrieve business name + GST status.
- **License** — Trade-specific professional licence (e.g., NSW plumbing licence). Per ADR 005, JOBBees verifies these manually per category — admin reviews vs the state register URL.
- **TFN** — Tax File Number. Australian tax ID. Stored AES-encrypted via Azure Key Vault (B-54). Never logged, never returned in API responses.
- **PCC / WWCC** — Police Check / Working With Children Check. Required for child-related categories. Out of MVP scope.

## Payments

- **PaymentIntent** — Stripe's primitive for an authorisation + capture flow. Used for jobs scheduled within 7 days (Mode 1).
- **SetupIntent** — Stripe's primitive for saving a card without charging. Used for jobs scheduled > 7 days out (Mode 2). Avoids Stripe's 7-day auth expiry.
- **Mode 1 / Mode 2** — Internal shorthand. Mode 1 = immediate-auth (PaymentIntent). Mode 2 = deferred-auth (SetupIntent + capture later).
- **Held funds** — Captured payment not yet released to Tasker because Connect onboarding is incomplete. Visible on Tasker's earnings screen as "Held funds: $X — complete payout setup to receive."
- **Re-auth flow** — When a PaymentIntent's 7-day authorisation is about to expire. We prompt the Client to re-authorise; fallback to SetupIntent path.
- **Capture window** — The time between Stripe authorising a payment and the platform actually charging it. Stripe's window is 7 days.
- **Payout** — Stripe Connect transfers the Tasker's earnings to their bank. Daily by default.
- **Application fee** — Our platform fee, taken from each successful payment via Stripe Connect's `application_fee_amount`.

## Tax

- **GST** — Goods and Services Tax. 10% in Australia. Applied to the platform fee only, not the full job amount.
- **RCTI** — Recipient-Created Tax Invoice. Issued by the platform on the Tasker's behalf when the Tasker doesn't have an ABN. Requires signed RCTI agreement.
- **Tax invoice** — Standard invoice issued to the Client on every captured payment.
- **ATO** — Australian Taxation Office. The tax authority.
- **SERR** — Sharing Economy Reporting Regime. Mandatory monthly export of contractor earnings to the ATO. Effective from 1 July 2023.
- **Annual income statement** — PDF generated each July listing all completed-job earnings per Tasker for the financial year. Required for their tax returns.

## AI & matching

- **Tier-0 mediator** — The autonomous Claude Sonnet agent that proposes resolutions to disputes under AUD $200. Targets 50-70% acceptance.
- **Admin co-pilot** — Claude Sonnet agent that generates a case brief for human admins on escalated disputes.
- **AI Welcome Agent** — Claude Haiku conversational onboarding walkthrough on first login. Skippable.
- **RAG support agent** — In-app chat using Claude Haiku + pgvector embeddings over FAQ content. Targets 60-80% L1 deflection.
- **pgvector** — PostgreSQL extension for vector storage + similarity search. We use HNSW indices for ranked feed + matching.
- **Embedding** — Vector representation of text. We use OpenAI `text-embedding-3-small` (1536-dim). Stored on `Job.embedding` and `TaskerProfile.embedding`.
- **ReAct** — Reasoning + Acting agent loop. Used for clarifying-question flow during job posting. Max 3 follow-ups.
- **Composite ranker** — The function that ranks taskers for a job. Weighted blend of: semantic similarity (cosine, 0.45), proximity (0.25), recency (0.15), budget alignment (0.10), category match (0.05).
- **Auto-invite** — BullMQ job that fires 2 hours after job publish if zero offers — pushes the top 20 matched Taskers.
- **Langfuse** — LLM observability tool. Traces every external AI call with model / prompt version / tokens / latency / cost.
- **NL → SQL** — Natural language → SQL translation. Used by AP-52 ad-hoc report builder.

## Trust & safety

- **Off-platform detection** — Regex-based scanner on every outgoing message to catch phone numbers, emails, social handles. Has an evasion corpus for coded variants ("zero four one two", emoji digits).
- **EXIF tampering check** — Validates photo metadata (timestamp + GPS) for completion-proof images. Flags Photoshop-edited photos.
- **Content moderation** — Azure Content Safety scan on every uploaded image (NSFW / violence / hate / self-harm). Async via BullMQ.
- **PII blur** — Azure Computer Vision OCR + Sharp blur on visible phone numbers / emails / addresses / ABNs in photos. Prevents off-platform contact via image.
- **Behavioural fraud scoring (B-48)** — Velocity / collusion / platform-leakage signals. Outputs `fraud_score` 0-1.
- **Device fingerprinting (M-229)** — FingerprintJS Pro at signup. Feeds fraud graph + multi-account detection.
- **Auto-suspend (B-57)** — Rules engine triggers suspension on: 3 disputes lost, 3 no-shows, rating < 3.0 with ≥ 10 reviews, fraud_score > 0.7.
- **Reinstatement queue (AP-58)** — Tasker submits remediation plan → Senior Admin reviews → approve/deny.

## Data & privacy

- **DSR** — Data Subject Request. Privacy Act compliance. Two endpoints: `/me/export` (download all data), `/me/delete` (anonymise).
- **Anonymisation** — Strip PII while preserving aggregate records for financial reporting. Financial records retained 7 years per ATO.
- **Consent ledger** — `ConsentRecord` model. Captures every consent (ToS, Privacy Policy, RCTI agreement, marketing) with version + IP + UA + timestamp.
- **Versioned consent capture (M-230)** — When ToS or Privacy Policy version changes, capture a new consent record per user on next login.
- **Retention** — Per-class data lifetimes (financial 7y, jobs 2y, threads 2y, AuditLog 7y, ConsentRecord 7y). Enforced by cron (B-58).
- **AuditLog** — Append-only record of every mutating action. Schema: `AuditLog`. DB-level REVOKE on UPDATE/DELETE from the app role.

## Architecture

- **cuid2** — Collision-resistant ID format. 24-char base36. Set in app code via `@paralleldrive/cuid2`. Replaces UUID + autoincrement.
- **Soft delete** — `deletedAt: DateTime?` field. Filter `where: { deletedAt: null }` by default via Prisma extension.
- **Idempotency-Key** — HTTP header required on every mutating endpoint. Server caches `(userId, route, key) → response` in Redis with 24h TTL.
- **BullMQ** — Redis-backed job queue. Used for: webhook handlers, embedding generation, notification dispatch, retention crons, content moderation.
- **DLQ** — Dead Letter Queue. Where failed BullMQ jobs land after 3 retries with exponential backoff. Admin can replay or drop.
- **Socket.IO** — Real-time WebSocket library. Used for messaging. Single-node at MVP (documented scaling ceiling).
- **HNSW** — Hierarchical Navigable Small Worlds. The pgvector index type we use. Fast similarity search, no retraining needed as data grows.
- **Prisma extension** — Plugin pattern for cross-cutting concerns (soft-delete filter, audit log on writes).

## Geography / regulation

- **ASIC** — Australian Securities and Investments Commission. Where ACNs are registered.
- **ACN** — Australian Company Number. 9-digit identifier for companies.
- **NSW Fair Trading** — NSW state regulator. We cross-check trade licences against their public register.
- **Privacy Act** — Australia's main privacy law. Governs DSR, retention, consent, PII handling.
- **Spam Act** — Australia's anti-spam law. Governs marketing email + SMS opt-out.
- **APP** — Australian Privacy Principles. APP 1-13. Privacy Policy must cover all 13.

## Sprint plan & tracking

- **Estimation v1.2** — Saiju's feature inventory (474 features, 398 in-scope, 1,420 raw hours). The canonical scope reference.
- **Scope reconciliation** — Saiju's 6-tab spreadsheet comparing the estimate vs sprint plan. 28 gap items resolved Jun 2026.
- **MVP** — Minimum Viable Product. Sprints 1-12 in our plan.
- **V2** — Post-MVP V1.1 / V2 work. Lives in `docs/sprints/post-mvp-deferred.md`.
- **In-scope items** — Feature inventory rows marked IN, IN★, or THIN.
- **IN** — Must build. Standard call.
- **IN★** — Must build, AI-dependent. Critical for differentiation.
- **THIN** — Build a simplified version at MVP.
- **POST** — Post-launch. Not in MVP.
- **DROP** — Cut permanently.
- **MDR** — Missing Decisions Report. Saiju's name for the latest scope revisions. Referenced as "MDR §5.2" etc. in row notes.

## Build tooling

- **CLAUDE.md** — Repo root + per-app instruction files. Hard rules, dos/don'ts, pointers. Always loaded into AI context.
- **Skill** — Custom Claude Code workflow in `.claude/skills/`. We have 6: stripe-payment, au-tax, pgvector-match, tier0-dispute, multimodal-extraction, security-review.
- **ADR** — Architecture Decision Record. Numbered files in `docs/adrs/`. 001-008 currently.
- **Coverage tracker** — `inventory/JOBBees_Feature_Inventory.csv`. Updated each Friday with `done [sprint-N, PR#nn]` status.
- **Widgetbook** — Flutter visual component catalog (Storybook equivalent). Lives at `apps/mobile/widgetbook/`.

## Common acronyms

- **CRUD** — Create, Read, Update, Delete
- **DTO** — Data Transfer Object (NestJS request/response shape)
- **JWT** — JSON Web Token (auth)
- **OAuth** — Open Authorization (social login)
- **OTP** — One-Time Password (SMS code)
- **TOTP** — Time-Based One-Time Password (Google Authenticator)
- **WAF** — Web Application Firewall (Cloudflare Pro)
- **CDN** — Content Delivery Network
- **CMK** — Customer-Managed Keys (Azure encryption)
- **IaC** — Infrastructure as Code (Terraform)
- **CI** — Continuous Integration
- **CD** — Continuous Deployment
- **SDK** — Software Development Kit
- **TTL** — Time To Live (cache expiry)

---

## When to update

- Whenever you find yourself googling a term used in the codebase, add it here.
- When a new acronym appears in an ADR or sprint doc, copy it here.
- If a term changes meaning (rename, scope change), update here AND in the relevant skill / sprint doc.

This file is grep-friendly by design. Don't reorganise into prose.
