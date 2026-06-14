# ADR-002: Database Conventions

**Status:** Accepted
**Date:** 2026-05-20
**Decider:** Engineering lead

## Context

Locking database conventions early. These are painful to retrofit and impact every model.

## Decision

### IDs: cuid2 strings (not auto-increment integers, not cuid1)

- All primary keys are `String @id`
- Generated via `@paralleldrive/cuid2` in app code, **not** via `@default(cuid())` (which is cuid1)
- Set explicitly with `id: createId()` in service code

**Rationale:**

- cuid2 is URL-safe, sortable enough for time-ordered display, collision-resistant
- No row-count leakage (vs auto-increment integers exposing how many rows exist)
- Single ID format across all tables; no mixing types

### Money: integer cents

- All monetary fields are `Int` representing cents (e.g., `amountCents`, `budgetCents`, `gstCents`, `platformFeeCents`)
- Never `Decimal`, never `Float`
- Format for display in app code (`Intl.NumberFormat`)

**Rationale:**

- Floating-point arithmetic produces rounding bugs that surface in production at the worst time
- Stripe accepts and returns cents — keeps boundary conversions to zero
- ATO requires whole-cent precision

### Time: UTC in DB, Australia/Sydney in UI

- All timestamps are `DateTime` (maps to PostgreSQL `timestamptz`)
- Store UTC
- Render in `Australia/Sydney` time zone in mobile and admin UIs
- Never store local time

**Rationale:**

- Multi-state Australia has AEDT/AEST shifts; storing local time creates DST bugs
- Future expansion to NZ has its own timezone
- UTC + render-time conversion is industry standard

### Standard fields on every table

- `createdAt DateTime @default(now())`
- `updatedAt DateTime @updatedAt`

### Soft delete on user-facing entities

- User, Job, Offer, Review, Thread (and similar) have `deletedAt DateTime?`
- Default filter `where: { deletedAt: null }` via a Prisma extension
- Hard delete only on ephemeral tables: OTPs, sessions, idempotency keys, drafts never published

**Rationale:**

- DSR (data subject request) deletion is anonymisation + soft-delete for user-facing entities
- Financial records (Payment, TaxInvoice, RCTI) are retained 7 years per ATO — never hard-deleted at user level
- Audit log is append-only — never deleted

### Anonymisation pipeline (for DSR deletion)

When a user requests deletion:

1. Replace `firstName`, `lastName`, `email`, `phone`, `defaultAddress` with `[deleted-user-{uuid}]` or `NULL`
2. Set `deletedAt` and `anonymisedAt` on User
3. Keep Payment, TaxInvoice, RCTI records intact (financial retention)
4. The `userId` foreign keys remain — but the dereferenced user shows anonymised data

### Foreign keys: explicit `onDelete`, manual indexes

- Every foreign key declares `onDelete` behaviour (`Cascade`, `Restrict`, `SetNull`, `NoAction`) — decide per relationship
- Always add `@@index([fkField])` for every FK column. **Prisma does not auto-index foreign keys.**

**Rationale:**

- Implicit FK behaviour bites in surprising places (deleting a User cascading to Payments is bad)
- Without FK indexes, joins become sequential scans as data grows

### Enums for state machines (not strings)

- Use Prisma enums for `UserRole`, `CategoryType`, `JobStatus`, `OfferStatus`, `PaymentState`, `DisputeState`, `KycStatus`, `ConnectStatus`
- Never store status as `String` (typo risk, no compiler check)

### JSON columns: opaque metadata only

- `Json?` for things like `extractedFields`, `exifJson`, `diffJson` on audit log
- Never use JSON for queryable fields — model those as real columns

### Audit log: append-only

- `AuditLog` table with `actorId`, `action`, `resourceType`, `resourceId`, `diffJson`, `ipAddress`, `userAgent`, `createdAt`
- Every sensitive write (suspension, refund, KYC override, dispute resolution, force-cancel) writes one row
- Indexes on `(resourceType, resourceId, createdAt)` and `(actorId, createdAt)`
- Never delete from this table

### Vector columns: Unsupported, queried via $queryRaw

- Embedding columns: `embedding Unsupported("vector(1536)")?`
- HNSW indexes added via raw SQL migrations
- Queried via `prisma.$queryRaw` with `<=>` cosine distance operator

### Country-aware schema

- `Country` table is the registry
- `User`, `Job`, `Payment`, `TaxInvoice` all have `countryCode String @default("AU")`
- Hardcoded to AU at MVP; logic ready for NZ post-launch

## Consequences

**Positive:**

- One ID format across all tables — no mixing types in joins or APIs
- No floating-point money bugs
- DSR / Privacy Act compliance scaffolded from day one
- Adding new countries doesn't require schema migration on every table

**Negative:**

- More verbose model definitions (cuid2 set in app code, not auto-default)
- FK index discipline requires constant attention (lint rule TBD)
- Vector queries require raw SQL — no Prisma type safety on those

## References

- `packages/prisma/schema.prisma`
- `PROJECT_CONTEXT.md` §9 Database Conventions
- `.claude/skills/pgvector-match/SKILL.md`
