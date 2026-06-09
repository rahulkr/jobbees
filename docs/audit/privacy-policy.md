# Privacy Policy (internal — customer-facing version drafted by counsel)

**Last reviewed:** TODO
**Owner:** TODO (Client + Australian counsel)

This is the internal companion document to the customer-facing privacy policy. The customer-facing policy must be authored by Australian counsel and **must match what the system actually does** (this document maps the policy claims to system behaviour).

## Customer-facing policy

TODO: link to the live policy URL once published.

## System behaviour mapping

Each section of the policy must be supported by a code reference.

| Policy claim | System behaviour | Code reference |
| --- | --- | --- |
| "We collect your name, email, phone, and address" | User table fields | `packages/prisma/schema.prisma` |
| "Payment card data is processed by Stripe; we never store it" | Stripe Elements iframe; PaymentIntent stores only `paymentMethodId` | `apps/api/src/modules/payments/stripe.service.ts` |
| "We send your task description to AI services to extract structured fields" | Gemini Flash via `TaskExtractionService`, with PII redaction | `apps/api/src/modules/tasks/extraction.service.ts` |
| "We share your information with Stripe for payments" | See `vendor-list.md` | `vendor-list.md` |
| "You can request access to your data" | DSR access endpoint | `apps/api/src/modules/privacy/dsr.controller.ts` |
| "You can request deletion of your data" | DSR delete endpoint + anonymisation pipeline | `apps/api/src/modules/privacy/dsr.service.ts` |
| "We retain financial records for 7 years" | TaxInvoice/Rcti/Payment retention policy | `data-retention-policy.md` |
| "Children under 18 are not permitted on the platform" | TODO: age verification at signup | TODO |

## Consent management

Versioned consent records in `ConsentRecord` table:
- Type (marketing, analytics, third-party sharing)
- Version of the policy at the time of consent
- Timestamp
- IP address + user agent at the time of consent

User can withdraw consent at any time via settings. Withdrawal is logged.

## Children's data

JOBBees is not intended for under-18s. Age check at signup (TODO). No targeting of children under 13 (COPPA equivalent).

## International data transfers

- Application data hosted in Australia (Azure Australia East)
- Some processing happens in the US (Stripe, Gemini, Anthropic, OpenAI, Twilio, SendGrid) — covered by DPAs
- See `vendor-list.md` for full list

## See also

- `data-classification-policy.md`
- `data-retention-policy.md`
- `dsr-process.md`
- `vendor-list.md`
- `australian-compliance.md`
