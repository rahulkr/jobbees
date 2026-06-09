# Vendor List + Subprocessor Inventory

**Last reviewed:** TODO
**Owner:** TODO (Dev)

Every third party that touches user data. Auditor will want this. Privacy Act may require us to publish a subprocessor list.

## Active vendors

| Vendor | Service | Data shared | Location | DPA / Compliance |
| --- | --- | --- | --- | --- |
| **Microsoft Azure** | Hosting (App Service, Postgres, Redis, Blob, Key Vault, App Insights, Content Safety) | All application data | Australia East | [Microsoft DPA](https://www.microsoft.com/licensing/docs/view/Microsoft-Products-and-Services-Data-Protection-Addendum-DPA) — IRAP-certified, GDPR-compliant, ISO 27001 |
| **Stripe** | Payments, Connect Express, Identity | Card data, KYC documents, bank details | US (PCI-compliant; we never see card numbers) | [Stripe DPA](https://stripe.com/legal/dpa) — PCI Level 1, SOC 1 + 2 |
| **Google (Gemini API)** | LLM (extraction, chat policing, support, budget nudge) | Redacted user content | US/global | [Google DPA](https://cloud.google.com/terms/data-processing-addendum) — zero-retention enabled on API |
| **Anthropic (Claude API)** | LLM (dispute mediator, admin co-pilot) | Redacted dispute evidence | US | [Anthropic DPA](https://www.anthropic.com/legal/dpa) — zero-retention enabled |
| **OpenAI (Embeddings API)** | Vector embeddings | Task title + description + tasker bio (no PII) | US | [OpenAI DPA](https://openai.com/policies/data-processing-addendum) — zero-retention on API tier |
| **Twilio** | SMS (OTP, critical alerts) | Phone numbers, SMS body | US/global | [Twilio DPA](https://www.twilio.com/legal/data-protection-addendum) — SOC 2, GDPR |
| **SendGrid (Twilio)** | Transactional email | Email addresses, email bodies | US/global | (covered by Twilio DPA) |
| **FCM (Google)** | Android push notifications | Push tokens (anonymous device IDs) | US/global | Google DPA |
| **APNS (Apple)** | iOS push notifications | Push tokens (anonymous device IDs) | US/global | Apple developer agreement |
| **Sentry** | Error tracking | Stack traces, request metadata (PII redacted) | US | [Sentry DPA](https://sentry.io/legal/dpa/) — SOC 2 |
| **PostHog or Mixpanel** | Analytics (TBD) | Anonymised event data | TBD | TBD |
| **Mapbox or Google Maps** | Geocoding (TBD) | Addresses for geocoding | TBD | TBD |
| **GitHub** | Source code hosting + CI | Source code (not production data) | US | [GitHub DPA](https://github.com/customer-terms/github-data-protection-agreement) — SOC 2, GDPR |

## Vendor evaluation criteria

When adding a new vendor:
- Does the vendor have a DPA? (mandatory)
- Where is the data hosted? Australia preferred; US acceptable with DPA
- Is the vendor SOC 2 / ISO 27001 certified?
- Does the vendor support zero-retention or data-deletion APIs?
- What happens if the vendor has a breach? (their notification SLA)

## Subprocessor disclosure

Privacy policy publishes the vendor list to users. Update this doc and the public privacy policy in sync.

## Vendor removal procedure

1. Stop sending new data to the vendor
2. Request deletion of existing data (DPA right)
3. Update vendor list (here + privacy policy)
4. Update code (remove integration)
5. Audit log entry

## See also

- `privacy-policy.md`
- `data-flow-diagram.md`
- `australian-compliance.md`
