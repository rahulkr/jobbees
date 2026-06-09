---
name: stripe-payment
description: Use whenever the user works on payment-related code — Stripe PaymentIntent, SetupIntent, Connect Express, refunds, capture, re-authorisation, payment state machine, RCTI triggers, idempotency on payment endpoints, or Stripe webhook handling. Reference for all payment architecture decisions.
---

# Stripe payment skill

## When to invoke

Any of these terms appearing in the user's request: payment, Stripe, PaymentIntent, SetupIntent, Connect, capture, refund, payout, webhook, idempotency on payment, RCTI, GST on platform fee, re-auth, dispute (Stripe-level), or any Stripe-related state machine work.

## Architecture facts (locked, do not re-derive)

### Stripe products used

- **PaymentIntent** with manual capture for tasks ≤ 7 days
- **SetupIntent** + saved PaymentMethod for tasks > 7 days or scheduled-future
- **Refund** (full + partial — partial refund is supported; partial capture is NOT)
- **Connect Express** for tasker payouts (bundled KYC + bank + tax)
- **Stripe Identity** for KYC (separate from Connect; bidding gated on Identity, payout gated on Connect)

### Capture window rule

Stripe authorisations expire after 7 days. The `transactionType` snapshot on `Task` and the `scheduledAt` field determine the flow:

- Task `scheduledAt` within 7 days AND duration ≤ 7 days → **PaymentIntent + manual capture**
- Task `scheduledAt` > 7 days in future OR duration > 7 days → **SetupIntent + saved PaymentMethod**, charged at completion
- If a PaymentIntent task drifts past 7 days mid-flight → **re-authorisation flow**: prompt poster to re-authorise, fall back to SetupIntent path if poster opts in

### Payment state machine (PaymentState enum)

```
authorised
captured
re-auth-required        (authorised + approaching 7d expiry)
setup-only              (SetupIntent created, PM saved, no charge yet)
failed                  (card declined at capture)
voided                  (cancelled before capture)
refunded                (full refund after capture)
partial-refunded        (partial refund after capture)
```

Allowed transitions:

- `authorised → captured | re-auth-required | voided | failed`
- `re-auth-required → authorised | voided | setup-only`
- `setup-only → captured | voided`
- `captured → refunded | partial-refunded`

Any other transition throws a state machine error.

### Idempotency

- Every mutating payment endpoint requires the `Idempotency-Key` HTTP header from the client
- Server stores `(userId, route, idempotencyKey) → response` in Redis with 24h TTL
- Server passes through the same idempotency key to the Stripe SDK call
- Replay of the same key returns the cached response without re-calling Stripe

### Held funds

Tasker can bid after Identity KYC passes. **First payout is gated on Connect Express onboarding completion.** Until then, captured funds are "held" — visible in:

- Mobile: persistent banner "Held funds: $X — complete payout setup to receive"
- Admin: `/payments/held-funds` dashboard listing all taskers with held amounts
- Reminder cadence: in-app + email + SMS at 24h, 72h, 7d after first held payout trigger

### GST + RCTI triggers

- Every successful capture writes a tax invoice (poster) — synchronous
- If tasker has no ABN, also writes an RCTI (Recipient-Created Tax Invoice) — synchronous, requires RCTI agreement consent on file
- GST calculated on the **platform fee** (the application_fee_amount), not the full task amount
- All tax PDFs stored in Azure Blob, signed URLs to download
- Monthly ATO sharing-economy reporting export aggregates all transactions

### Promo codes

- Applied at PaymentIntent creation as a discount (reduces both task amount and platform fee proportionally)
- Single-use vs multi-use, expiry, per-user max — config-driven
- Audit log entry on every code application

## Hard rules — never violate

1. **Never call the Stripe SDK from a controller.** All Stripe calls go through `StripeService` in `apps/api/src/modules/payments`.
2. **Never use partial capture.** Stripe supports it but our state machine doesn't — use refunds for adjustments.
3. **Never auto-migrate Stripe webhook signing secrets.** They're env vars, rotated manually.
4. **Never trust the webhook body without signature verification.** Use `stripe.webhooks.constructEvent()`.
5. **Never write to the database without a transaction** that also writes the audit log.
6. **Never let GST/RCTI logic merge without tax advisor sign-off.** Flag the PR description: "Tax-advisor sign-off required: [advisor name + date]".
7. **Never skip the idempotency middleware on payment endpoints.** Test for it.
8. **All money in cents (Int).** No Decimal/Float.
9. **Test mode keys only in `.env.local` and CI.** Live keys only in Azure Key Vault.

## File pointers

- `apps/api/src/modules/payments/stripe.service.ts` — the wrapper
- `apps/api/src/modules/payments/payment.service.ts` — state machine
- `apps/api/src/modules/payments/payment.controller.ts` — REST endpoints
- `apps/api/src/modules/payments/webhooks.controller.ts` — Stripe webhooks
- `apps/api/src/modules/tax/` — GST + RCTI + ATO reporting
- `packages/prisma/schema.prisma` — Payment, TaxInvoice, Rcti, AuditLog models

## Common tasks

### Adding a new payment endpoint

1. Define DTO with class-validator
2. Add to `payment.controller.ts` with `@UseInterceptors(IdempotencyInterceptor)`
3. Call `StripeService` method — never SDK directly
4. Wrap DB write + audit log in `prisma.$transaction`
5. Add unit + e2e tests using Stripe test mode

### Handling a new Stripe webhook event

1. Add the event type to the switch in `webhooks.controller.ts`
2. Resolve to a domain action (e.g., `payment.intent.succeeded` → `paymentService.markCaptured()`)
3. Idempotent by design — Stripe retries; use `eventId` to dedupe
4. Always return 200 within 5 seconds — push slow work to BullMQ

### Adding a Connect Express step

1. Talk to `StripeConnectService` (separate from main `StripeService`)
2. Update the Connect onboarding status tracker on the User model
3. Trigger held-funds reminder if needed
4. Audit log every onboarding state change
