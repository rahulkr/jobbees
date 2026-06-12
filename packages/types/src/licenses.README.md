# `packages/types/src/licenses.ts`

**Status:** to be written in **Sprint 2** alongside the Category seed PR.
**Consumed by:** Sprint 4 License module (mobile + backend + admin scaffold).
**Authoritative spec:** `docs/adrs/005-kyc-strategy.md` → "Allowed license types per category (MVP seed data)".

This file is the **single source of truth** for which license types the JOBBees app accepts. Mobile dropdowns, backend bid-time guard, and admin License Review Queue all import from here. Do not duplicate this list anywhere.

## What lives in this file

Two exported constants and one derived type:

```ts
export const ALLOWED_LICENSE_TYPES = {
  electrical: [ ... ],
  plumbing:   [ ... ],
  drainage:   [ ... ],
  gasfitting: [ ... ],
  asbestos:   [ ... ],
  refrigerated_ac: [ ... ],
  pest_control:    [ ... ],
  builder:    [ ... ],
} as const;

export const ISSUING_STATES = ["NSW", "VIC", "QLD", "WA", "SA", "TAS", "ACT", "NT"] as const;

export type LicenseTypeSlug =
  typeof ALLOWED_LICENSE_TYPES[keyof typeof ALLOWED_LICENSE_TYPES][number]["slug"];

export type IssuingState = typeof ISSUING_STATES[number];
```

The exact rows for `ALLOWED_LICENSE_TYPES` are reproduced verbatim in ADR 005. Copy them from there when writing the file so there's no transcription drift.

## How callers use it

### Mobile (Flutter) — drop the JSON in via codegen

`packages/types/src/licenses.ts` is the TS source. For Flutter, run `pnpm types:gen-flutter` (script to be added in Sprint 2) which produces `apps/mobile/lib/generated/licenses.dart` — same data, same slugs, same labels.

### Backend — DTO validation

```ts
import { ALLOWED_LICENSE_TYPES, LicenseTypeSlug } from '@jobbees/types';

const allowedForCategory = (categoryId: string): LicenseTypeSlug[] => {
  const list = ALLOWED_LICENSE_TYPES[categoryId as keyof typeof ALLOWED_LICENSE_TYPES];
  return list ? list.map((t) => t.slug) : [];
};

// In the License DTO validator
if (!allowedForCategory(dto.categoryId).includes(dto.licenseType)) {
  throw new BadRequestException({
    code: 'INVALID_LICENSE_TYPE',
    message: `licenseType "${dto.licenseType}" is not allowed for this category`,
  });
}
```

### Admin (Next.js) — render dropdown + display labels

```tsx
import { ALLOWED_LICENSE_TYPES } from "@jobbees/types";

const labels = Object.fromEntries(
  Object.values(ALLOWED_LICENSE_TYPES).flat().map(t => [t.slug, t.label])
);

// Render the friendly label next to the slug stored on a License row
<dt>License type</dt>
<dd>{labels[license.licenseType] ?? license.licenseType}</dd>
```

## Adding a new license type post-MVP

1. Add the row to `ALLOWED_LICENSE_TYPES` in this file
2. Update the matching table in `docs/adrs/005-kyc-strategy.md`
3. Update flutter codegen output (or just commit the regenerated `.dart` file)
4. No schema migration needed

## Removing a license type

Don't remove. Old License rows would orphan. If a license type becomes obsolete, mark the affected APPROVED rows EXPIRED via admin script and update the policy doc. Do not delete the slug from the constant — existing AuditLog entries reference it.

## Notes for the implementer

- Slugs are kebab-case, lowercase, immutable.
- Display labels are mixed-case AU-English ("Licence" not "License") — match the AU register spelling so the admin verification cross-check is unambiguous.
- The Authority field is informational; not stored on the License row. Admins use it to know which register to cross-check.
- Issuing state is independent of license type — taskers select state separately so a "Plumber Licence" issued in QLD is still accepted (admin reviews case-by-case at MVP since only NSW has a cross-check link).
