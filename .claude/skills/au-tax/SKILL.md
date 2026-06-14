---
name: au-tax
description: Use whenever the user works on Australian tax compliance — GST calculation, ABN/ABR lookup, RCTI generation, ATO sharing-economy reporting, tax invoice PDFs, or any code touching the tax/RCTI/invoice modules. HIGH-RISK area for AI hallucination — review every line manually.
---

# Australian tax skill

## When to invoke

Any of: GST, ABN, ABR, RCTI, ATO, sharing-economy, tax invoice, tax advisor, withholding, tax rate, tax PDF, AUSTRAC.

## ⚠️ CRITICAL: review every line you generate against this skill

This is the highest-risk area in the codebase for AI hallucination. Specific things AI gets subtly wrong:

- Whether GST applies to the full job amount or just the platform fee
- Whether RCTI is required for non-ABN taskers (it is) or non-GST-registered taskers (different concept)
- ATO sharing-economy reporting field schema (it's specific and mandatory)
- Whether platform fee includes GST or excludes it (excludes, then GST added on top)
- Threshold for GST registration ($75k AUD/year) — applies to the platform's GST registration, not per-job

**Always have the tax advisor review the SQL + the PDF templates + the ATO export schema before merging.**

## Architecture facts (locked)

### GST calculation

- GST rate: 10% (current Australian rate, single-bracket)
- **Applied to the platform fee only**, not the full job amount
- Formula: `gstCents = round(platformFeeCents * 0.10)`. **Round half-up**, never banker's rounding (ATO requires).
- Platform fee = `job.budgetCents * commissionRate` (commission rate per category, default 15%)
- Final breakdown returned to caller:
  ```
  jobAmount      = X
  platformFee    = Y (commission% of X)
  gst            = Y * 0.10
  taskerPayout   = X - Y
  totalCharged   = X + GST
  ```

### ABN + ABR

- ABN = 11-digit Australian Business Number
- ABR = Australian Business Register (free public lookup API)
- Validation: ABN checksum algorithm (weighted digits, mod 89 must equal 0). Implement in `AbnValidator.validate()`.
- ABR lookup: hits `abr.business.gov.au/json/AbnDetails.aspx?abn=XXX&guid=YYY`. Free tier (1k/day) is fine for MVP.
- Re-check ABN status quarterly via cron — taskers can lose their ABN registration.

### RCTI (Recipient-Created Tax Invoice)

- Required when the platform pays a tasker who **does NOT have an ABN**
- Platform issues the RCTI **on behalf of the tasker** (we are the "recipient" creating the invoice)
- Requires a signed RCTI agreement from the tasker (one-time, at signup)
- RCTI agreement must include the specific wording mandated by ATO — get from tax advisor
- RCTI PDF must include: invoice number, date, platform ABN, tasker name + address + bank, line items, GST breakdown, "Recipient-created tax invoice" header

### Tax invoice (client side)

- Issued to the client on every captured payment
- Format: invoice number, date, platform ABN, client name + email, line items (job description + platform fee + GST), total
- PDF stored in Azure Blob, signed URL on download

### ATO sharing-economy reporting

- Mandatory monthly export — Sharing Economy Reporting Regime (effective from 1 July 2023)
- Fields required (verify with tax advisor; these are the typical fields, do NOT trust without confirmation):
  - Tasker name, ABN/TFN (or notation if neither), date of birth, address
  - Total amount paid to tasker in the period
  - GST collected (if applicable)
  - Date range
- Export format: CSV per ATO spec, uploaded to ATO Online Services
- Cron job runs on the 5th of each month, exports the prior month

### Decision tree for issuing tax docs

```
On payment captured:
  Generate tax invoice (client side) — always

  If tasker.abn is null OR !abrLookup(tasker.abn).gstRegistered:
    Require RCTI agreement on file (else block payout)
    Generate RCTI (tasker side)
  Else:
    Tasker issues their own tax invoice externally; we don't generate one
```

### State machine for tax document triggers

```
Offer.accepted → Job.completed → Payment.captured → Payout.released → RCTI.issued
                                       ↓
                                  TaxInvoice.issued (always, to client)
```

RCTI is triggered on payout release (not on offer acceptance, not on capture). This is the ATO-correct timing: RCTI documents the actual transfer of money to the tasker.

## Hard rules — never violate

1. **Never compute GST in floating point.** Always integers (cents). Multiply by 10, divide by 100, round half-up.
2. **Never issue an RCTI without an agreement on file.** Block the payout. Show the agreement signing flow.
3. **Never modify a generated tax invoice after issue.** New corrections are credit notes, not amendments.
4. **Never let ATO export logic merge without tax advisor sign-off.** Field schema is mandatory.
5. **Always include "Tax Invoice" or "Recipient-Created Tax Invoice" header in the PDF** (ATO requirement).
6. **Always store the platform ABN in config**, not hardcoded. Single source of truth.
7. **Never expose the ABR API key or tax-system credentials in logs.**
8. **Always run new tax logic through `pnpm test:tax`** — a dedicated test suite with ATO-validated fixtures.
9. **PDF templates in a versioned folder.** Don't edit historical RCTIs; new template = new version.

## File pointers

- `apps/api/src/modules/tax/gst.service.ts` — GST calculation
- `apps/api/src/modules/tax/abn.service.ts` — ABN validation + ABR lookup
- `apps/api/src/modules/tax/rcti.service.ts` — RCTI generation
- `apps/api/src/modules/tax/invoice.service.ts` — tax invoice generation
- `apps/api/src/modules/tax/ato-export.service.ts` — monthly sharing-economy export
- `apps/api/src/modules/tax/pdf-templates/` — versioned PDF templates
- `apps/api/test/tax/` — tax test suite with ATO fixtures

## Common changes

### Adding a new tax invoice line item type

1. Update the line item interface in `invoice.service.ts`
2. Update the PDF template (bump version)
3. Add a unit test with the new line item
4. Have the tax advisor confirm wording

### Changing the GST rate (e.g., future ATO change)

1. Single config entry: `TAX_GST_RATE` env var, default 0.10
2. New rate only applies to invoices issued after the effective date — never retro-apply
3. Add a migration documenting the change date

### Adding a new country's tax model (e.g., NZ GST)

1. Add a new tax module per the AU template: `apps/api/src/modules/tax/nz/`
2. Service interface implements `TaxModelService`
3. Route by `country.taxModel` field on the Job
4. AU and NZ both use 10%/15% GST but with different RCTI rules — keep modules separate

## Tax advisor handoff

When code is ready for tax advisor review, include in the PR description:

- Link to the relevant tax service files
- Test output showing example calculations
- Sample generated PDFs (RCTI + tax invoice)
- Sample ATO export CSV
- Specific questions: "Is the platform fee approach correct?", "Is the RCTI wording compliant?", "Is the ATO export field schema correct?"
