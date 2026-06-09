# Data Flow Diagram

**Last reviewed:** TODO
**Owner:** TODO

Shows where PII, financial data, and AI-bound content flows. Used by the IT auditor and the Privacy Impact Assessment.

## PII data flow

TODO: insert PII data flow diagram showing:

- Where PII enters the system (signup, profile edit, KYC, payment methods)
- Where it's stored (User table, Stripe Identity, Stripe Connect)
- Where it crosses external boundaries (Stripe, Gemini, Anthropic, OpenAI, Twilio, SendGrid)
- Where it's redacted (PII redaction layer before LLM calls)
- Where it's deleted/anonymised (DSR pipeline)

## Payment data flow

TODO: insert payment data flow diagram showing:

- Card capture in Stripe Elements (Stripe's hosted iframe, never touches our servers)
- PaymentIntent creation via NestJS API
- Authorisation hold → capture → payout to tasker's Connect account
- Refund flow
- Tax invoice + RCTI generation
- ATO sharing-economy reporting export

## AI / LLM data flow

TODO: insert AI data flow showing:

- User content (task description, messages, dispute evidence)
- PII redaction step
- LLM provider (Gemini Flash, Claude Sonnet)
- Response back through the API to the client
- Zero-retention settings on direct provider calls

## Cross-border data

| Data type                       | Provider                                   | Location                                           |
| ------------------------------- | ------------------------------------------ | -------------------------------------------------- |
| TODO: Card data                 | Stripe                                     | US (PCI-compliant; data never touches our servers) |
| TODO: KYC documents             | Stripe Identity                            | TODO confirm region                                |
| TODO: User PII (post-redaction) | Gemini API                                 | US/global                                          |
| TODO: User PII (post-redaction) | Anthropic API                              | US                                                 |
| TODO: User PII (post-redaction) | OpenAI API                                 | US                                                 |
| TODO: SMS content               | Twilio                                     | US/global                                          |
| TODO: Email content             | SendGrid                                   | US/global                                          |
| TODO: Image content             | Azure Content Safety                       | TODO confirm AU region                             |
| TODO: Application data          | Azure (Postgres, Redis, Blob, App Service) | Australia East                                     |

## See also

- `data-classification-policy.md`
- `encryption-policy.md`
- `vendor-list.md`
