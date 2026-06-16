# Sprint 5 — Messaging + Payments core + OTP swap to Firebase

**Dates:** Mon 17 Aug → Fri 28 Aug 2026 (10 working days)
**Theme:** A client and tasker chat in-app about an accepted offer, the client authorises a payment hold, the tasker can see the funds are committed but not yet paid out. **Plus**: the MockOtpService from Sprint 1 gets swapped for the real production OTP provider so phone-verified accounts are real before real money flows.
**Hours budget:** ~171 (42 mobile, 109 backend, 20 Flutter Web parity) — most payment-heavy sprint. Was 118h baseline; +3h OTP swap, +5h scope reconciliation, +13h backend reality, +20h Flutter Web parity, +12h Estimation v1.2 verification (B-56 +8, B-53 moderation orchestrator +4).
**Mid-sprint demo:** Fri 21 Aug
**End-of-sprint demo:** Fri 28 Aug

## Goal in one sentence

By Friday 21 Aug, client + tasker chat in-app about the accepted job → client authorises a payment hold via Stripe → tasker sees "$X held" in earnings dashboard → if scheduled >7d, SetupIntent path is used so funds can be re-authorised closer to completion.

## Scope — inventory rows

### Mobile (apps/mobile)

| ID  | Item                                      | Call | Hrs | Notes           |
| --- | ----------------------------------------- | ---- | --- | --------------- |
| 109 | Inbox / thread list                       | IN   | 3   |                 |
| 110 | Conversation view (text)                  | IN   | 4   |                 |
| 111 | Photo attachment                          | IN   | 2   |                 |
| 112 | File / PDF attachment                     | THIN | 2   |                 |
| 115 | Read receipts                             | IN   | 2   |                 |
| 120 | Report user / message                     | IN   | 2   |                 |
| 121 | Block user                                | IN   | 2   |                 |
| 122 | Off-platform contact warning banner       | IN   | 1   |                 |
| 123 | Message search                            | IN   | 4   | Backend in §2.5 |
| 124 | Push notifications for messages           | IN   | 1   |                 |
| 125 | Thread freeze on dispute open (UI state)  | IN   | 1   |                 |
| 126 | Add card (Stripe Elements / native sheet) | IN   | 3   |                 |
| 127 | Remove / update card                      | IN   | 1   |                 |
| 128 | Set default card                          | IN   | 1   |                 |
| 129 | Apple Pay / Google Pay (toggle in Stripe) | IN   | 1   |                 |
| 130 | Stripe-hosted onboarding webview          | IN   | 2   |                 |
| 131 | Payout history (tasker)                   | IN   | 3   |                 |
| 132 | Earnings summary (tasker)                 | IN   | 3   |                 |
| 133 | Transaction history (client)              | IN   | 3   |                 |

**Mobile total: ~42h**

### Backend (apps/api)

| ID   | Item                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | Call | Hrs | Notes                                                                                                                                                                                                                                                                                                                                                                                 |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---- | --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 274  | Socket.IO server (single-node)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | IN   | 6   |                                                                                                                                                                                                                                                                                                                                                                                       |
| 276  | Message persistence (Postgres)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | IN   | 3   |                                                                                                                                                                                                                                                                                                                                                                                       |
| 277  | Read receipts                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | IN   | 2   |                                                                                                                                                                                                                                                                                                                                                                                       |
| 279  | Attachment upload + virus scan                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | IN   | 4   | Local storage + clamav stub at MVP                                                                                                                                                                                                                                                                                                                                                    |
| 280  | Thread state (open / frozen)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | IN   | 2   |                                                                                                                                                                                                                                                                                                                                                                                       |
| 281  | Off-platform regex detection (phone, email) + **coded-variant + unicode evasion corpus** (per scope reconciliation #13)                                                                                                                                                                                                                                                                                                                                                                                                                                                        | IN   | 4   | +1h for the evasion corpus. Regex misses creative encodings (`"zero four one two"`, emoji-substituted digits, "the gram", zero-width unicode). Add test corpus `apps/api/test/fixtures/moderation-evasion.txt` with ≥40 known bypass patterns; regex must catch ≥30. Documented MVP limitation: LLM-classifier upgrade is in [post-mvp-deferred.md](./post-mvp-deferred.md) item #10. |
| 283  | Thread freeze on dispute                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | IN   | 1   |                                                                                                                                                                                                                                                                                                                                                                                       |
| 284  | Message search backend (FTS or trigram)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | IN   | 6   |                                                                                                                                                                                                                                                                                                                                                                                       |
| 285  | Live location share endpoint                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | IN   | 4   | WebSocket channel (mobile UI in S6)                                                                                                                                                                                                                                                                                                                                                   |
| 286  | Stripe PaymentIntent (create / capture / void)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | IN   | 8   |                                                                                                                                                                                                                                                                                                                                                                                       |
| 287  | Stripe Refund — full and partial                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | IN   | 4   |                                                                                                                                                                                                                                                                                                                                                                                       |
| 288  | Manual capture flow ≤7d                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | IN   | 5   | Stripe 7-day window                                                                                                                                                                                                                                                                                                                                                                   |
| 289  | SetupIntent + saved PaymentMethod for >7d / scheduled                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | IN   | 12  | The big one                                                                                                                                                                                                                                                                                                                                                                           |
| 290  | Re-auth flow on capture expiry                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | IN   | 8   | Detect approaching 7d, trigger UI prompt                                                                                                                                                                                                                                                                                                                                              |
| 296  | Payment state machine                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | IN   | 8   | AUTHORISED/CAPTURED/RE_AUTH_REQUIRED/SETUP_ONLY/FAILED/VOIDED/REFUNDED/PARTIAL_REFUNDED                                                                                                                                                                                                                                                                                               |
| 297  | Idempotency middleware (Redis-backed)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | IN   | 6   | Required header, 24h TTL                                                                                                                                                                                                                                                                                                                                                              |
| 298  | Stripe idempotency key pass-through                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | IN   | 2   |                                                                                                                                                                                                                                                                                                                                                                                       |
| 299  | Webhook signature verification                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | IN   | 2   |                                                                                                                                                                                                                                                                                                                                                                                       |
| B-19 | **Webhook DLQ (BullMQ dead-letter queue)** — failed Stripe webhook handlers retry 3× with exponential backoff, then land in `webhooks:dlq`. Each DLQ entry stores: stripe event ID, raw signed payload, attempt count, last error, first-seen + last-attempt timestamps. (Per scope reconciliation #24. Admin replay viewer = S9.)                                                                                                                                                                                                                                             | IN   | 4   | Closes the "payment reliability" half of gap #24. Tests PAY-020..023 require this. DLQ inspection at MVP is via psql / BullMQ Redis CLI; admin UI lands S9.                                                                                                                                                                                                                           |
| B-56 | **Payment lifecycle edge cases — dispute hold + release + payout-ready gate** (per Estimation v1.2 verification 14 Jun) — three coordinated gaps: (1) `held_indefinitely` reserve state on dispute open — locks payout until resolved, prevents premature transfer to tasker. (2) Auto-release reserve on dispute closure — B-31 triggers Stripe transfer after outcome recorded. (3) `PAYOUT_READY` gate on task completion — blocks completion if tasker Connect account isn't `charges_enabled` + `payouts_enabled`, shows hard error with deep-link to Connect onboarding. | IN   | 8   | MDR §5.4. Critical compliance — prevents tasker payouts before dispute resolution; prevents completion → orphaned funds. Tax advisor sign-off required.                                                                                                                                                                                                                               |
| B-53 | **Moderation pipeline orchestrator** (per 14 Jun Estimation v1.2 verification) — BullMQ fan-out: new task / new message / new photo / new review → relevant moderation checks (Azure Content Safety, EXIF validation, off-platform regex, future LLM classifier). Reuses B-37 notification dispatcher pattern. Each check writes back to ModerationResult with confidence + decision.                                                                                                                                                                                          | IN   | 4   | Estimate v1.2 IN. Centralised orchestrator means a new content type only needs ModerationConfig registration, not separate pipelines per surface.                                                                                                                                                                                                                                     |
| 302  | Application fee / platform fee logic                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | IN   | 3   |                                                                                                                                                                                                                                                                                                                                                                                       |
| 530  | **FirebaseOtpService — swap from mock to real Firebase Phone Auth**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | IN   | 3   | New: real Firebase Admin SDK integration; verifies the `OTP_PROVIDER=firebase` env path; AuditLog confirms no mock OTPs verified in prod since switch                                                                                                                                                                                                                                 |

**Backend total: ~97h** (compresses well — many small + a few big tickets; +3h for OTP swap; +5h from scope reconciliation: BullMQ DLQ +4h, regex evasion corpus +1h)

### Flutter Web parity (added per founder direction 14 Jun 2026)

| ID    | Item                                                                                                                                              | Call | Hrs | Notes                                                                                                                       |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ---- | --- | --------------------------------------------------------------------------------------------------------------------------- |
| FW-16 | **Web parity — inbox, conversation view (text + photo + file), read receipts, report/block, off-platform warning, message search, thread freeze** | IN   | 8   | Socket.IO has first-class web support; messaging UX is close to mobile parity.                                              |
| FW-17 | **Web parity — Stripe Elements (web-native), add/remove/default card, Apple Pay (Safari only) + Google Pay (Chrome only) via Stripe**             | IN   | 7   | Stripe Elements is web-native — no Flutter abstraction needed. Use the official Stripe Elements component inside an iframe. |
| FW-18 | **Web parity — payout history, earnings summary, transaction history, receipt PDF viewer**                                                        | IN   | 5   | PDF viewing is native browser; mobile uses a PDF widget.                                                                    |

**Flutter Web parity total: ~20h**

### Schema additions

- New `Thread` model: `id`, `jobId`, `clientId`, `taskerId`, `state ENUM(OPEN, FROZEN_BY_DISPUTE, CLOSED)`, `createdAt`, `updatedAt`, `@@unique([jobId])` (one thread per job)
- New `Message` model: `id`, `threadId`, `senderId`, `body Text`, `attachments Json?`, `readAt DateTime?`, `createdAt`, plus `@@index([threadId, createdAt])`
- New `Attachment` model: `id`, `messageId`, `blobUrl`, `mimeType`, `sizeBytes`, `scanStatus ENUM(PENDING, CLEAN, FAILED)`, `createdAt`
- New `BlockedUser` model: `userId`, `blockedUserId`, `@@id([userId, blockedUserId])`, `createdAt`
- New `Report` model: `id`, `reporterId`, `targetType ENUM(MESSAGE, USER, JOB)`, `targetId`, `reason`, `details Text?`, `createdAt`, `reviewedAt`, `reviewerId`
- New `Payment` model: `id`, `jobId`, `offerId`, `clientId`, `amountCents Int`, `currency String @default("AUD")`, `state PaymentState`, `stripePaymentIntentId`, `stripeSetupIntentId`, `stripePaymentMethodId`, `capturedAt`, `expiresAt`, `voidedAt`, `refundedCents Int @default(0)`, `applicationFeeCents Int`, `createdAt`, `updatedAt`
- New `PaymentEvent` model: `id`, `paymentId`, `fromState`, `toState`, `stripeEventId`, `idempotencyKey`, `payloadJson Json`, `createdAt` — immutable, append-only
- New `IdempotencyKey` model? No — keep in Redis (per CLAUDE.md rule 3)
- AuditLog writes on Payment state transitions (already supported)

## Definition of done

Same as Sprint 1, plus per skill §H and the PR template payment section:

- [ ] All money in `Int` cents — no Decimal/Float (skill §H1)
- [ ] Currency stored alongside every amount (skill §H2)
- [ ] Every Stripe mutating call has `{ idempotencyKey: 'stripe:${ourKey}' }` (skill §C2)
- [ ] `Idempotency-Key` header required on every payment/refund mutation (skill §C1)
- [ ] Webhook signature verified BEFORE any DB write (skill §H5)
- [ ] AuditLog write on every payment state transition (skill §I1)
- [ ] Test: webhook with invalid signature → 400, no side effect (skill §L2)
- [ ] Test: replay payment intent creation with same idempotency key → returns same response, no double charge
- [ ] **Manual line-by-line review of every payment file by the eng lead (CLAUDE.md rule 2)** — recorded in PR description

## Friday demo script (end-of-sprint Fri 21 Aug)

5-6 min screencast (paired devices):

```
00:00 — "Sprint 5 wrap. Messaging + payments. Two devices."
00:15 — Device A (client): from accepted offer, tap chat icon → thread opens.
00:30 — Device B (tasker): notification arrives, tap → thread opens on
        their side.
00:45 — Type a message. Read receipt appears on A. Both directions.
01:00 — Attach a photo (e.g., site location pic). Send.
01:15 — Trigger off-platform warning: type "call me on 0412 345 678" →
        warning banner appears, suggests in-app call (not implemented).
01:30 — Switch to A: tap Settings → Payment methods → Add card. Stripe
        Elements native sheet appears. Enter test card 4242 4242 4242
        4242. Save.
01:50 — Back to thread. Tap "Authorise payment" CTA tied to the offer.
        Confirm $X.
02:05 — Show payment state: AUTHORISED. Held but not captured.
02:15 — Switch to B (tasker): earnings summary screen → "$X held".
02:20 — **Bonus demo — OTP swap.** Show a fresh tasker signup. The OTP
        now arrives via real Firebase SMS (no longer the mock code 000000).
        Caveat: AU pooled sender used, branded sender via Notifyre later.
        Cost telemetry shows ~$0.02 per SMS (well within free tier).
02:30 — Device A: post a scheduled-for-2-weeks-out job (from S3 flow),
        accept an offer on it. Show SetupIntent path used (no immediate
        hold) — card saved for later auth. State: SETUP_ONLY.
02:55 — Trigger re-auth flow manually (admin/dev tool to fast-forward
        7d): re-auth prompt appears on client device. Tap → confirms.
03:10 — Show webhook log: Stripe webhook signature verified, payment
        state transitioned, AuditLog entry written.
03:30 — Show partial refund flow: admin triggers $X refund on the first
        job. Payment moves to PARTIAL_REFUNDED.
03:45 — Show transaction history (client) and payout history (tasker).
04:00 — Block user demo: block the tasker → can't send messages anymore.
04:15 — Coverage report. Stoplight + asks. End.
```

## Risks

| Risk                                                             | Likelihood | Impact             | Mitigation                                                                                                                               |
| ---------------------------------------------------------------- | ---------- | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Stripe SetupIntent + re-auth flow is conceptually complex        | High       | High               | Build skeleton first (just state transitions), then plug in real Stripe calls; use `.claude/skills/stripe-payment/SKILL.md` for guidance |
| Idempotency layer subtle bug double-charges                      | Low        | Critical           | Manual review every line + integration test specifically for replay                                                                      |
| Socket.IO scaling at MVP (single-node)                           | Low        | Low (at MVP scale) | POST per inventory row 275 — Redis adapter                                                                                               |
| Off-platform regex false positives (e.g., "phone book" → blocks) | Medium     | Low                | Tune regex; allow override via admin                                                                                                     |
| Webhook signature secret leaked                                  | Low        | High               | Store in Key Vault by S10; for now `.env.local` only, never `.env.example`                                                               |
| Stripe test mode response shapes differ from prod                | Medium     | Medium             | Use Stripe-fixtures gem-equivalent for tests; integration test against real Stripe test env                                              |
| Partial captures (milestone billing) creep into scope            | Low        | Medium             | DROPPED per inventory row 291 — don't let it in                                                                                          |

## Explicitly NOT in scope

- Partial captures for milestone-billed work — DROPPED (inventory row 291)
- Typing indicators — DROPPED (inventory row 116)
- Voice messages — DROPPED (inventory row 113)
- Message reactions — DROPPED (inventory row 114)
- Mute / archive / pin thread — DROPPED (inventory rows 117-119)
- Live location share UI on mobile — Sprint 6 (inventory row 102)
- Tax invoice PDFs — Sprint 6 (rows 134-137, 309-310)
- Re-auth UX on mobile beyond minimal — full polish Sprint 6
- ~~Stripe webhook DLQ + replay tool — POST (inventory row 300)~~ **MOVED IN per scope reconciliation #24.** DLQ lands this sprint (BullMQ); admin replay viewer UI lands Sprint 9.
- Apple Pay / Google Pay deep integration — Stripe handles (inventory row 129)

## Day-by-day rough plan

| Day          | Mobile                                       | Backend                                                           |
| ------------ | -------------------------------------------- | ----------------------------------------------------------------- |
| Mon 10 (D1)  | Inbox + thread list scaffold.                | Thread + Message Prisma models + migrations. Socket.IO bootstrap. |
| Tue 11 (D2)  | Conversation view + text send.               | Message persistence + WebSocket events. Read receipts.            |
| Wed 12 (D3)  | Photo + file attachment UI.                  | Attachment upload + scan stub.                                    |
| Thu 13 (D4)  | Report / block / off-platform banner.        | Off-platform regex. Report + Block models.                        |
| Fri 14 (D5)  | Mid-sprint demo + catch-up.                  | Same. Message search backend.                                     |
| Mon 17 (D6)  | Add card (Stripe Elements).                  | Stripe PaymentIntent + idempotency middleware.                    |
| Tue 18 (D7)  | Remove/default card. Payment authorise CTA.  | Payment state machine + AuditLog hooks.                           |
| Wed 19 (D8)  | SetupIntent path UI. Re-auth prompt UI.      | SetupIntent + saved PM. Re-auth detection cron.                   |
| Thu 20 (D9)  | Payout/earnings/transaction history. Polish. | Webhook handlers + signature verify. Application fee.             |
| Fri 21 (D10) | End-of-sprint demo + CSV update.             | Confirm CI green. Tag `sprint-05-end`.                            |

## Definition of "shippable"

- [ ] All 19 mobile rows done
- [ ] All 19 backend rows done
- [ ] Payment authorise + capture works end-to-end in Stripe test mode
- [ ] SetupIntent + re-auth works for jobs scheduled >7d
- [ ] Idempotency key replay test passes
- [ ] Webhook signature failure test passes
- [ ] Eng lead's manual line-by-line review attached to every payment PR
- [ ] `./scripts/coverage.sh` reports ~60% MVP
- [ ] Sprint 6 detail doc reviewed
- [ ] Tax advisor engaged (CLAUDE.md rule 4) — confirmed available for Sprint 6 reviews

## Expected PRs (~15-18)

- `feat(prisma): Thread, Message, Attachment, BlockedUser, Report, Payment, PaymentEvent`
- `feat(api/messaging): Socket.IO server + message persistence`
- `feat(api/messaging): read receipts + thread state + freeze on dispute`
- `feat(api/messaging): attachment upload + scan stub`
- `feat(api/messaging): off-platform regex + report/block`
- `feat(api/messaging): message search (Postgres FTS)`
- `feat(api/messaging): live location share endpoint`
- `feat(api/payments): payment state machine + AuditLog hooks`
- `feat(api/payments): Stripe PaymentIntent (create/capture/void) + idempotency`
- `feat(api/payments): Stripe Refund (full + partial)`
- `feat(api/payments): manual capture flow ≤7d`
- `feat(api/payments): SetupIntent + saved PM for >7d`
- `feat(api/payments): re-auth flow on capture expiry`
- `feat(api/payments): webhook signature verification + handlers`
- `feat(mobile): inbox + thread + message UI`
- `feat(mobile): attachments + report + block + off-platform banner`
- `feat(mobile): add/remove card + payment authorise CTA`
- `feat(mobile): SetupIntent + re-auth + payout/earnings/transactions`
