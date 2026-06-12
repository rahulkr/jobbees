# ADR-005: Verification strategy — Stripe Connect + ABN + manual license review

**Status:** Accepted
**Date:** 2026-06-09
**Decider:** Engineering lead + client
**Supersedes:** earlier draft of this ADR which proposed Didit / manual / Stripe Identity as a 3-way vendor choice for identity KYC

## Context

JOBBees needs to verify taskers (the people receiving money) before allowing them to take paid jobs. Our earlier draft of this ADR framed this as a single problem ("identity verification") and considered vendors like Didit, Stripe Identity, and a manual review queue.

That framing was wrong. There are actually **three different verification concerns** which a generic "identity vendor" doesn't address well:

1. **Stripe Connect KYC** — legally required by Stripe (and Australian AML/CTF) for any account receiving payouts. Stripe Connect Express handles this end-to-end on Stripe's side. JOBBees doesn't have to build it.
2. **ABN verification** — required by ATO sharing-economy reporting. Tasker provides ABN, JOBBees calls the free ABR API to confirm.
3. **Professional license** — required by AU state regulators (Fair Trading) for certain trades: electrical, plumbing, gas fitting, building (over $5K NSW), asbestos, refrigerated air-con, pest control. Most JOBBees categories DON'T require any professional license.

What posters actually care about for trust signals is:

- The tasker has a license to do this category of work (when applicable)
- The tasker has been paid out before successfully (Stripe Connect green)
- The tasker has completed prior jobs with good reviews (social proof)
- The tasker's email and phone are verified (basic trust)

Adding an identity-vendor KYC on top of Stripe Connect would be duplicative — Stripe is already doing identity verification. The honest gap is **license verification per category**, which no vendor can automate for AU (state registers are not unified, no API exists).

## Decision

**Three-layer trust model. No identity vendor at MVP.**

| Layer                               | Required for                                      | How                                                                            | Cost                   |
| ----------------------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------ | ---------------------- |
| **Email + phone verified**          | All taskers (and posters)                         | Email link + phone OTP (mock dev → real Sprint 5 per ADR 008)                  | $0                     |
| **Stripe Connect Express KYC**      | All taskers receiving payouts                     | Stripe handles end-to-end in their onboarding flow                             | $0 to JOBBees          |
| **ABN verified**                    | All taskers                                       | ABR API call (free) — checksum + business name match                           | $0                     |
| **License verified** (per category) | Only taskers bidding on licensed-trade categories | Tasker uploads license image, admin manually reviews against AU state register | Free (admin time only) |

**Insurance verification** is POST (post-MVP). Adds an "Insured" badge for premium taskers. Defer.

## Why we skip Didit / Stripe Identity / similar

- Stripe Connect already does the legal identity check for payouts. Adding another identity vendor is wearing two belts.
- Posters care about "can this person do plumbing legally" — not "is this person real". Stripe + reviews + completion history cover the latter.
- Identity vendors cost $0.33 - $1.50 per check. For MVP scale that's small money — but the build effort (vendor integration + webhook handling + KYC data minimisation rules) is real (~13-15 hours).
- Removing one vendor relationship simplifies IT audit + Privacy Act subprocessor disclosure.
- License verification is what genuinely differentiates "real verified tasker" from "scammer" for licensed trades — and that has to be manual regardless.

## Category model — which categories require a license

Per NSW Fair Trading (other AU states broadly similar — `state` recorded per license):

| Category                                           | License required?                                                                                                            | `requiresLicense` | `licenseRequiredOverCents`                                   |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ----------------- | ------------------------------------------------------------ |
| Electrical                                         | ✅ Always (NSW Fair Trading electrical license)                                                                              | `true`            | `null`                                                       |
| Plumbing / drainage / gas fitting                  | ✅ Always (NSW Fair Trading licensed plumber/gasfitter)                                                                      | `true`            | `null`                                                       |
| Asbestos removal                                   | ✅ Always (SafeWork NSW)                                                                                                     | `true`            | `null`                                                       |
| Refrigerated air conditioning                      | ✅ Always                                                                                                                    | `true`            | `null`                                                       |
| Pest control                                       | ✅ Always                                                                                                                    | `true`            | `null`                                                       |
| Building / construction                            | ⚠️ Conditional — licensed builder required only for jobs over **$5,000 AUD** (NSW Fair Trading Home Building Act 1989, s. 4) | `false`           | `500000`                                                     |
| Tree work (over height/size limits)                | ⚠️ Conditional                                                                                                               | `false`           | TBD — defer to post-MVP, currently treat as `false` / `null` |
| Handyman (under licensed trades, under thresholds) | ❌ No license required                                                                                                       | `false`           | `null`                                                       |
| Cleaning                                           | ❌ No license required                                                                                                       | `false`           | `null`                                                       |
| Gardening (small jobs)                             | ❌ No license required                                                                                                       | `false`           | `null`                                                       |
| Moving / delivery (non-commercial vehicle)         | ❌ No license required                                                                                                       | `false`           | `null`                                                       |
| IT support / tutoring / personal services          | ❌ No license required                                                                                                       | `false`           | `null`                                                       |
| Ikea assembly / furniture install                  | ❌ No license required                                                                                                       | `false`           | `null`                                                       |

In the `Category` Prisma model, add **two** fields:

- `requiresLicense: Boolean @default(false)` — license always required for this category.
- `licenseRequiredOverCents: Int?` — license required only when the task value is at or above this cents threshold. `null` means no conditional rule.

A category may set `requiresLicense: true` (unconditional) OR `licenseRequiredOverCents: <N>` (conditional). Both can be `false`/`null` (never required). It's nonsensical to set `requiresLicense: true` AND `licenseRequiredOverCents` — the unconditional flag wins, but seed data should avoid this combination.

**At MVP only the Builder category uses `licenseRequiredOverCents` (set to `500000` = $5,000 AUD per NSW Fair Trading Home Building Act 1989).** Other AU states have different thresholds (VIC ~$10K, QLD ~$3,300, WA ~$20K). Per-state thresholds are POST-MVP — at MVP we hardcode the NSW value and accept that the rule is slightly conservative for other states. Future enhancement: split into `BuilderThresholdByState` lookup table.

## Allowed license types per category (MVP seed data)

When a tasker picks a licensed-trade category and taps "Add a licence", the app shows a dropdown of allowed license types for that category. Each row below is the **complete set** of allowed values for that category at MVP. The slug is what's stored in `License.licenseType`; the display label is what the mobile app and admin queue render.

**Source-of-truth note:** the slugs and display labels below are based on NSW Fair Trading + SafeWork NSW + ARCtick (federal refrigerant) registers as of mid-2026. The list should be sanity-checked by the lawyer in Sprint 11 before live mode in case any nomenclature has shifted. Categories may add license types post-MVP without a schema migration (it's a TypeScript constant, not an enum).

### Electrical

| Slug                              | Display label                                 | Issuing authority |
| --------------------------------- | --------------------------------------------- | ----------------- |
| `electrical-contractor`           | Electrical Contractor Licence                 | NSW Fair Trading  |
| `electrical-qualified-supervisor` | Qualified Supervisor Certificate — Electrical | NSW Fair Trading  |

### Plumbing

| Slug      | Display label   | Issuing authority |
| --------- | --------------- | ----------------- |
| `plumber` | Plumber Licence | NSW Fair Trading  |

### Drainage

| Slug      | Display label   | Issuing authority |
| --------- | --------------- | ----------------- |
| `drainer` | Drainer Licence | NSW Fair Trading  |

### Gas fitting

| Slug        | Display label     | Issuing authority |
| ----------- | ----------------- | ----------------- |
| `gasfitter` | Gasfitter Licence | NSW Fair Trading  |

### Asbestos removal

| Slug               | Display label                            | Issuing authority |
| ------------------ | ---------------------------------------- | ----------------- |
| `asbestos-class-a` | Asbestos Removal — Class A (friable)     | SafeWork NSW      |
| `asbestos-class-b` | Asbestos Removal — Class B (non-friable) | SafeWork NSW      |

### Refrigerated air conditioning

| Slug                              | Display label                             | Issuing authority |
| --------------------------------- | ----------------------------------------- | ----------------- |
| `refrigerant-handling-full`       | Refrigerant Handling Licence — Full       | ARCtick (federal) |
| `refrigerant-handling-restricted` | Refrigerant Handling Licence — Restricted | ARCtick (federal) |

### Pest control

| Slug                         | Display label                      | Issuing authority          |
| ---------------------------- | ---------------------------------- | -------------------------- |
| `pest-management-technician` | Pest Management Technician Licence | NSW Fair Trading / NSW EPA |

### Building / construction (conditional — bid ≥ $5K AUD or any hourly bid)

| Slug               | Display label                                        | Issuing authority |
| ------------------ | ---------------------------------------------------- | ----------------- |
| `builder-full`     | Builder Licence — Full                               | NSW Fair Trading  |
| `builder-low-rise` | Builder Licence — Low-Rise (residential ≤ 3 storeys) | NSW Fair Trading  |

### Total: 13 license type slugs across 8 categories

### Shared TypeScript constant (mobile + backend + admin consume this)

The dropdown is enforced by a shared constant exported from `packages/types/src/licenses.ts`. Sprint 4 implements the License module and Sprint 2 seeds the Category data — both pull the dropdown values from this single source:

```ts
// packages/types/src/licenses.ts
// Single source of truth for allowed license types per category.
// Mobile dropdowns + backend bid-time guard + admin review queue all import this.

export const ALLOWED_LICENSE_TYPES = {
  electrical: [
    {
      slug: 'electrical-contractor',
      label: 'Electrical Contractor Licence',
      authority: 'NSW Fair Trading',
    },
    {
      slug: 'electrical-qualified-supervisor',
      label: 'Qualified Supervisor Certificate — Electrical',
      authority: 'NSW Fair Trading',
    },
  ],
  plumbing: [{ slug: 'plumber', label: 'Plumber Licence', authority: 'NSW Fair Trading' }],
  drainage: [{ slug: 'drainer', label: 'Drainer Licence', authority: 'NSW Fair Trading' }],
  gasfitting: [{ slug: 'gasfitter', label: 'Gasfitter Licence', authority: 'NSW Fair Trading' }],
  asbestos: [
    {
      slug: 'asbestos-class-a',
      label: 'Asbestos Removal — Class A (friable)',
      authority: 'SafeWork NSW',
    },
    {
      slug: 'asbestos-class-b',
      label: 'Asbestos Removal — Class B (non-friable)',
      authority: 'SafeWork NSW',
    },
  ],
  refrigerated_ac: [
    {
      slug: 'refrigerant-handling-full',
      label: 'Refrigerant Handling Licence — Full',
      authority: 'ARCtick',
    },
    {
      slug: 'refrigerant-handling-restricted',
      label: 'Refrigerant Handling Licence — Restricted',
      authority: 'ARCtick',
    },
  ],
  pest_control: [
    {
      slug: 'pest-management-technician',
      label: 'Pest Management Technician Licence',
      authority: 'NSW Fair Trading / NSW EPA',
    },
  ],
  builder: [
    { slug: 'builder-full', label: 'Builder Licence — Full', authority: 'NSW Fair Trading' },
    {
      slug: 'builder-low-rise',
      label: 'Builder Licence — Low-Rise (residential ≤ 3 storeys)',
      authority: 'NSW Fair Trading',
    },
  ],
} as const;

export type LicenseTypeSlug =
  (typeof ALLOWED_LICENSE_TYPES)[keyof typeof ALLOWED_LICENSE_TYPES][number]['slug'];
```

### Issuing state — separate field

The 8-value `issuingState` field is independent of license type:

`NSW` · `VIC` · `QLD` · `WA` · `SA` · `TAS` · `ACT` · `NT`

At MVP we display all 8 in the dropdown but only NSW-issued licences will be cross-checked against a register (the admin review queue link goes to NSW Fair Trading). Non-NSW licences land in the queue and the admin can either approve based on visual inspection or reject with a note to re-upload once the tasker re-licenses in NSW. Expanding cross-check coverage to other states is a Sprint 10/11 polish task.

### Excluded by design at MVP

- **Owner-builder permits** — not allowed. These authorise work on your own home only, not paid work for others.
- **Trade certificates / Cert III qualifications** — these are training credentials, not legal-practice licences. Don't gate bidding.
- **Apprentice / restricted-supervised licences** — too narrow at MVP; reject and request a full licence.
- **Combined licences from VIC / QLD / etc. that bundle differently from NSW** — admins approve case-by-case; no special dropdown handling.

## Schema additions (replaces earlier "KYC vendor" schema)

```prisma
model Category {
  // existing fields...
  requiresLicense           Boolean   @default(false)
  // Conditional licensing — license required only when task value >= threshold (cents).
  // null = not conditional. Only used at MVP for Builder (500000 = $5,000 AUD,
  // NSW Fair Trading Home Building Act 1989). Other AU states have different
  // thresholds — POST-MVP we'll move this to a per-state lookup table.
  // Invariant: do NOT set both requiresLicense=true AND licenseRequiredOverCents.
  licenseRequiredOverCents  Int?
  // ...
}

model License {
  id              String        @id // cuid2
  userId          String
  user            User          @relation(fields: [userId], references: [id], onDelete: Cascade)
  categoryId      String
  category        Category      @relation(fields: [categoryId], references: [id])
  licenseType     String        // One of the slugs in ALLOWED_LICENSE_TYPES (e.g., "plumber", "electrical-contractor", "builder-low-rise"). Backend validates against the shared constant on every License insert/update.
  licenseNumber   String        // The license number from the AU state register
  issuingState    String        // "NSW", "VIC", "QLD", "WA", "SA", "TAS", "ACT", "NT"
  expiresAt       DateTime      // The license expiry date from the document
  uploadedBlobUrl String        // Photo of the physical license card / register screenshot
  status          LicenseStatus @default(PENDING)
  reviewedAt      DateTime?
  reviewerId      String?
  reviewer        User?         @relation("LicenseReviews", fields: [reviewerId], references: [id])
  reviewerNotes   String?
  createdAt       DateTime      @default(now())

  @@unique([userId, categoryId])  // one license per tasker per category
  @@index([userId])
  @@index([categoryId])
  @@index([status])
  @@index([expiresAt])  // for the auto-expiry cron
}

enum LicenseStatus {
  PENDING
  APPROVED
  REJECTED
  EXPIRED  // auto-transitioned by cron when expiresAt < now()
}
```

User model: keep existing `kycStatus` field but it now reflects Stripe Connect state (NOT_STARTED → PENDING → APPROVED via Stripe Connect webhooks). Remove `kycProvider` field (no longer needed).

## Bid logic

Backend: `POST /bids` runs the License guard as follows. Pseudocode:

```ts
function checkLicenseRequired(
  bid: { totalCents: number; isHourly: boolean },
  task: { categoryId: string },
  category: { requiresLicense: boolean; licenseRequiredOverCents: number | null },
): { required: true; reason: string } | { required: false } {
  // Unconditional license category (plumbing, electrical, etc.)
  if (category.requiresLicense) {
    return { required: true, reason: 'ALWAYS_REQUIRED' };
  }

  // Conditional license category (Builder).
  if (category.licenseRequiredOverCents != null) {
    // Hourly bids on a conditional category: we cannot pre-determine
    // total spend, so conservatively require the license.
    if (bid.isHourly) {
      return { required: true, reason: 'HOURLY_ON_CONDITIONAL_CATEGORY' };
    }
    // Fixed-price bid: compare bid total to threshold.
    if (bid.totalCents >= category.licenseRequiredOverCents) {
      return { required: true, reason: 'OVER_THRESHOLD' };
    }
  }

  return { required: false };
}
```

If a license is required, look up `License where userId = bidder.id AND categoryId = task.categoryId AND status = APPROVED AND expiresAt > now()`. If no row, return 403 with a structured error:

```json
{
  "code": "LICENSE_REQUIRED",
  "categoryId": "bld_...",
  "categoryName": "Building",
  "reason": "OVER_THRESHOLD",
  "licenseRequiredOverCents": 500000,
  "bidTotalCents": 750000,
  "message": "This task requires a licensed builder because your bid of $7,500 is over the $5,000 NSW Fair Trading threshold. Add your builder licence under Profile → Licences to bid."
}
```

Mobile uses `reason` + `licenseRequiredOverCents` to render a context-specific message:

- `ALWAYS_REQUIRED` → "This task requires a licensed plumber/electrician/etc."
- `OVER_THRESHOLD` → "This task requires a licensed builder because the job is over $5,000."
- `HOURLY_ON_CONDITIONAL_CATEGORY` → "Hourly bids on Builder jobs require a licensed builder regardless of estimated value."

### Why we check the bid amount, not the poster's budget

The poster's budget is an estimate; the bidder's actual bid is the contractual amount. Using the bid amount means: an honest tasker stays within their license, a dishonest tasker would have to commit fraud (bidding low then padding the invoice) to evade the guard. The guard catches the easy case; AML/insurance catches the rest.

### Hourly bids on Builder

Hourly bids have no fixed total, so we cannot algorithmically tell whether the job will land above $5,000. Two safe options:

1. **Require the license on all hourly Builder bids** (current default — captured in the guard above).
2. **Block hourly entirely for Builder** (forces fixed-price bidding).

Option 1 is the gentler UX and is what the guard implements. We can switch to option 2 if abuse is observed.

## License expiry cron

Daily cron job:

- Find all `License` rows with `status = APPROVED` AND `expiresAt < now() + 14 days`
- Email tasker: "Your plumbing license expires in 14 days. Upload renewal to keep bidding on plumbing jobs."
- Find all `License` rows with `status = APPROVED` AND `expiresAt < now()`
- Transition status to `EXPIRED`
- AuditLog entry

## Admin tooling

`apps/admin` (Sprint 9) gets a **License Review Queue** that mirrors the existing planned KYC Review Queue:

- List of PENDING licenses
- Tasker name + category + license type + uploaded photo + license number + issuing state + claimed expiry
- Admin can: Approve / Reject / Request more info
- Each decision writes to AuditLog with admin actorId
- Recommended verification step: cross-check the license number against the public AU state register (e.g., NSW Fair Trading public licence search), record the verification timestamp + URL in reviewer notes

## Consequences

- **Sprint 2 scope changes** (~85h budget stays the same):
  - REMOVE: Didit SDK integration + KYC vendor webhook handler (~13h freed)
  - ADD: License upload UI (mobile) + admin license review queue scaffold + License Prisma model + bid-time guard (~13h)
  - Net effort: same total. Less external dependency.
- **Sprint 9 admin scope** gains a License Review queue (~4h)
- **No identity vendor relationship** — simplifies subprocessor disclosure
- **Posters get a more useful trust signal** — "Verified Plumber" badge means "we've checked your licence is valid", not just "we've checked you're a real person"

## What we DON'T do at MVP

- Auto-verification against state registers (no unified API exists in AU). Admin manually cross-checks.
- Insurance verification (`Insurance` model) — POST, only build if posters specifically demand it.
- Police / WWCC (Working with Children Check) — POST, only if we add child-related categories.
- Driver-license-grade identity check beyond Stripe Connect — not needed.

## References

- NSW Fair Trading licence search: https://www.service.nsw.gov.au/transaction/check-a-tradesperson-licence
- Stripe Connect Express AU requirements: https://stripe.com/docs/connect/identity-verification-api
- ABR ABN lookup: https://abr.business.gov.au/Tools/AbnLookup
- `docs/sprints/sprint-02-kyc-tasker-connect.md` (will be retitled to reflect new scope)
- `docs/audit/vendor-list.md` (Didit removed from pending list)
- `docs/audit/australian-compliance.md`
