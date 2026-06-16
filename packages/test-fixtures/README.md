# @jobbees/test-fixtures

Named factory functions for test data. Use across api + admin + web test suites.

## Why factories?

Hand-rolling test data ages badly. By Sprint 6 you have 200 fixtures across 50 test files. When the schema changes (e.g., a new required field), you update 200 places.

Factories give you:

- **One place to change** when the schema changes
- **Consistent test data** (no copy-paste mutations)
- **Faker-backed defaults** so the fixture LOOKS like real production data (without ever using real PII)
- **Composable overrides** for specific test scenarios

## CLAUDE.md compliance

Per CLAUDE.md hard rule 9 + the AI-behaviour guidance:

> Don't generate test data with realistic PII patterns (use clearly-fake `@example.com`, AU `+61400000000` test format)

This package enforces that:

- All emails are `*@example.com` or `*@test.jobbees.com.au`
- All phone numbers use the AU `+61400000000` test format
- All ABNs use Stripe test ABNs from a known list (never randomly generated, never real)
- All TFNs use the ATO's test TFN (`123 456 782`)
- All addresses use NSW Fair Trading test addresses for licence cross-checks
- All names use a small fixed list ("Aria Tasker", "Rohan Client", etc.) — clearly fake

## Pattern

```ts
import { aClient, aTasker, aJob, anOffer } from '@jobbees/test-fixtures';

// Defaults — gives you a perfectly valid object
const client = aClient();

// Overrides — change just what matters for this test
const verifiedTasker = aTasker({
  kycStatus: 'APPROVED',
  abn: '53 004 085 616',
  emailVerified: true,
});

// Compose
const acceptedJob = aJob({
  client,
  status: 'ACCEPTED',
  acceptedOfferId: anOffer({ tasker: verifiedTasker }).id,
});
```

## File layout

```
packages/test-fixtures/
├── package.json
├── tsconfig.json
├── README.md (this file)
└── src/
    ├── index.ts          — re-exports
    ├── faker-config.ts   — locale + seed config; PII guardrails
    ├── users.ts          — aClient, aTasker, anAdmin, aSuperAdmin
    ├── jobs.ts           — aJob, aDraftJob, aPublishedJob, anAcceptedJob, aCompletedJob, aCancelledJob
    ├── offers.ts         — anOffer, anAcceptedOffer, aWithdrawnOffer
    ├── payments.ts       — aPayment, anAuthorisedPayment, aCapturedPayment, aRefundedPayment
    ├── disputes.ts       — aDispute, anOpenDispute, aResolvedDispute
    ├── reviews.ts        — aReview, aBlindReview, aRevealedReview
    ├── licenses.ts       — aLicense, anApprovedLicense, anExpiredLicense
    └── seeds/            — seed data for local dev
        ├── happy-path.ts — A complete happy-path scenario (client + tasker + job + offer + payment + completion + review)
        └── dispute.ts    — Same but escalates to dispute
```

## Seeding the dev DB

```bash
pnpm --filter @jobbees/test-fixtures seed:happy-path
pnpm --filter @jobbees/test-fixtures seed:dispute
```

These wire the factories into the Prisma client and insert. Use this instead of writing one-off seed scripts.

## When you add a new model

1. Add `aXxx()` and one or two variants in `src/<model>.ts`
2. Re-export from `src/index.ts`
3. Add an entry in the file-layout list above
4. The AI should default to using your factory in any new test it writes

## Test data shouldn't change behaviour

A test that asserts `payment.amountCents === 8400` should set `amountCents: 8400` explicitly. Don't rely on the factory default for assertions. Use defaults for fields you don't care about.

## What this package is NOT

- Not a Prisma client wrapper (factories return plain objects; you decide whether to `prisma.create()` them)
- Not a request mocker (use msw or supertest for that)
- Not a snapshot store (use vitest's built-in snapshots)

It's just typed factory functions with safe defaults.
