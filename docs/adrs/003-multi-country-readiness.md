# ADR-003: Multi-Country Readiness

**Status:** Accepted
**Date:** 2026-05-20
**Decider:** Engineering lead (per client direction — "be ready for NZ + other countries")

## Context

Client direction: launch AU-only at MVP, but design the system to expand to New Zealand and potentially other markets later. Currency, tax model, locale, regulations all differ by country.

Two extremes:

- Build full multi-country support now → significantly increases MVP scope without business validation
- Hardcode AU everywhere → expensive retrofit later

## Decision

**Schema is country-aware from day one. Logic is AU-only at MVP.**

### Schema additions

```prisma
model Country {
  code          String   @id  // ISO 3166-1 alpha-2: "AU", "NZ"
  name          String
  currencyCode  String        // "AUD", "NZD"
  defaultLocale String        // "en-AU"
  taxModel      String        // "AU_GST_RCTI_ATO", "NZ_GST", ...
  phonePrefix   String        // "+61", "+64"
  isActive      Boolean       @default(false)
}

model User       { countryCode String @default("AU") country Country @relation(...) }
model Job        { countryCode String @default("AU") country Country @relation(...) }
model Payment    { countryCode String @default("AU") country Country @relation(...) }
model TaxInvoice { countryCode String @default("AU") country Country @relation(...) }
```

`countryCode` defaults to `"AU"` everywhere. Seed inserts AU as the only `isActive` country at MVP.

### Code conventions

- All tax logic dispatches on `country.taxModel`:
  ```ts
  switch (country.taxModel) {
    case 'AU_GST_RCTI_ATO': return auTaxService.calculate(...);
    case 'NZ_GST':           return nzTaxService.calculate(...);  // post-MVP
    default: throw new Error(`Unsupported tax model: ${country.taxModel}`);
  }
  ```
- Tax modules live under `apps/api/src/modules/tax/<country>/` (e.g., `au/`, `nz/`)
- Currency formatting reads `country.currencyCode` — never hardcoded `'AUD'`
- Phone number formatting reads `country.phonePrefix`

### What we DO build at MVP

- `Country` table with single AU row
- `countryCode` columns + foreign keys on User, Job, Payment, TaxInvoice
- Currency formatting helper that reads from `country.currencyCode`
- Tax dispatch in tax service (currently only routes to AU)

### What we DON'T build at MVP

- Country selector UI (mobile and admin)
- NZ tax module (different RCTI rules, different GST registration thresholds)
- Multi-currency cart logic
- Country-specific compliance docs (NZ Privacy Act etc.)
- Localised content (privacy policy, T&Cs translated)

### How NZ would be added later (~2-3 weeks of work)

1. INSERT NZ row into Country table, set `isActive = true`
2. Build `apps/api/src/modules/tax/nz/` module implementing `TaxModelService` interface
3. Register the new module in the tax dispatcher
4. Test currency formatting in NZD
5. Add NZ phone OTP support (E.164 with +64 prefix)
6. Translate privacy policy + T&Cs (legal step)
7. Build country selector UI (mobile + admin)
8. NZ-specific Stripe Connect onboarding (some fields differ)

No schema migration on existing tables. Just one INSERT into Country and one new module.

## Consequences

**Positive:**

- Adding NZ later is a contained ~2–3 weeks of work, not a 2-month rewrite
- Schema is forward-compatible without bloating the MVP
- Currency display already country-aware (free for multi-currency stripe payouts)
- Tax module isolation prevents AU rules from leaking into NZ logic

**Negative:**

- Slight schema bloat (every relevant table has `countryCode` even though all rows are "AU")
- Tax dispatch switch is overkill for a single country at MVP
- Country relation in queries means an extra join or eager load on every operation involving country-aware data (mitigated by indexed FK)

## Alternatives considered

| Option                                      | Why rejected                                                             |
| ------------------------------------------- | ------------------------------------------------------------------------ |
| Hardcode "AU" everywhere                    | Brutal retrofit cost when adding NZ; client direction was explicit       |
| Build full multi-country support at MVP     | YAGNI for the second country until launch + traction validate it         |
| Single Currency table without Country table | Country is broader than currency (locale, tax model, phone, regulations) |
| String-typed `countryCode` without FK       | No referential integrity; would allow typos                              |

## References

- `packages/prisma/schema.prisma` — `Country` model
- `apps/api/src/modules/tax/` — tax module dispatch
- `PROJECT_CONTEXT.md` §10 Multi-Country Readiness
