# ADR-004: Category Types (Transactional vs Lead)

**Status:** Accepted
**Date:** 2026-05-20
**Decider:** Engineering lead (per client direction — "design for lead categories in future")

## Context

Client direction: all MVP categories are transactional (payment flows through the platform). In the future, the platform may introduce **lead-generation categories** where the platform charges a fee for the introduction but the actual transaction happens off-platform.

Examples:

- **Transactional** (MVP): "Clean my house for $80" — poster pays platform $80, tasker gets $68, platform takes $12 fee.
- **Lead** (post-MVP): "Renovate my bathroom — find me a contractor" — poster posts, qualified contractors pay platform $20 each to view contact details, the renovation contract is signed off-platform.

The two flows differ fundamentally:

- Transactional: escrow, dispute mediator, RCTI, ATO reporting, cancellation fees
- Lead: just a lead-purchase model, no escrow, no completion proof, simpler refunds

## Decision

Schema field `Category.type` is `enum CategoryType { TRANSACTIONAL | LEAD }`. Default `TRANSACTIONAL`. Task snapshots the type at creation as `Task.transactionType`. All MVP categories are TRANSACTIONAL.

### Schema

```prisma
enum CategoryType {
  TRANSACTIONAL  // payment flows through platform (MVP)
  LEAD           // poster→tasker intro, payment off-platform (post-MVP)
}

model Category {
  // ...
  type          CategoryType @default(TRANSACTIONAL)
  leadFeeCents  Int?         // only used if type = LEAD
}

model Task {
  // ...
  transactionType CategoryType  // snapshot from Category at creation; immutable per task
}
```

### Why snapshot on Task

If the client ever flips a Category from TRANSACTIONAL to LEAD (or vice versa) mid-life, **in-flight tasks should retain their original behaviour**. Snapshotting at task creation prevents a transactional task suddenly demanding lead-fee payment because someone changed a category config.

### MVP code path

Every payment, dispute, RCTI, and cancellation service starts with:

```ts
if (task.transactionType !== 'TRANSACTIONAL') {
  throw new BadRequestException(`Lead-type tasks not supported at MVP (task ${task.id})`);
}
```

This asserts the invariant in every place that would need a different code path. When LEAD support arrives, we replace each `throw` with a branch.

### What's NOT built at MVP

- Lead payment flow (tasker pays a fee to unlock contact details — different Stripe pattern)
- Lead-specific review trigger (no "task completed" event since platform doesn't see the deal close)
- Lead-specific UI in mobile (e.g., "Pay $20 to view contact info" sheet)
- Admin tools for managing lead pricing per category

### How LEAD support is added later (~3-4 weeks of work)

1. Implement `LeadPaymentService` — different Stripe flow (PaymentIntent on tasker, immediate capture, no escrow)
2. Update `Bid` model — leads have a different acceptance flow (poster "selects" rather than "accepts"; contact details unlock per tasker who paid)
3. Update `Task` model — leads have no completion proof, no dispute window, no auto-confirm
4. New mobile UI: lead-pay flow, contact-revealed screen for taskers
5. Admin UI for setting `leadFeeCents` per LEAD category
6. Replace all `throw` assertions with proper branching in payment / dispute / cancellation / RCTI services

## Consequences

**Positive:**

- Schema is forward-compatible — no migration on Task/Category when LEAD support lands
- Asserting `TRANSACTIONAL` everywhere prevents accidental misuse at MVP
- Snapshot on Task means category config changes don't retroactively affect in-flight work

**Negative:**

- Every payment-touching service has the `transactionType` assertion at the top — boilerplate
- Slight cognitive overhead reading the code at MVP ("why is this check here if there's only one type?")
- `leadFeeCents` column is nullable forever for TRANSACTIONAL categories — schema noise

## Alternatives considered

| Option                                                     | Why rejected                                                              |
| ---------------------------------------------------------- | ------------------------------------------------------------------------- |
| Hardcode "transactional" everywhere, add type column later | Retrofit pain — need to update every payment service when LEAD lands      |
| Two separate task tables (TransactionalTask, LeadTask)     | Massive refactor for what's still essentially "a task posted by a poster" |
| Boolean flag instead of enum                               | Doesn't scale to a third type (rental, subscription, etc.)                |
| Don't snapshot type on Task                                | Mid-life category type changes would corrupt in-flight task behaviour     |

## References

- `packages/prisma/schema.prisma` — `Category.type`, `Task.transactionType`
- `PROJECT_CONTEXT.md` §11 Category Type System
