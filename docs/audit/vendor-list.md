# Vendor List + Subprocessor Inventory

**Last reviewed:** 2026-06-12
**Owner:** TODO (Dev)

Every third party that touches user data. Auditor will want this. Privacy Act may require us to publish a subprocessor list.

## Locked vendors

| Vendor                      | Service                                                                                                         | Status                   | Data shared                                    | Location                                      | DPA / Compliance                                                                                                                                                                       |
| --------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------ | ---------------------------------------------- | --------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Microsoft Azure**         | Hosting (App Service, Postgres, Redis, Blob, Key Vault, App Insights, Content Safety)                           | ✅ Locked                | All application data                           | Australia East                                | [Microsoft DPA](https://www.microsoft.com/licensing/docs/view/Microsoft-Products-and-Services-Data-Protection-Addendum-DPA) — IRAP-certified, GDPR-compliant, ISO 27001                |
| **Cloudflare Pro**          | WAF + DDoS + CDN + DNS + TLS termination                                                                        | ✅ Locked (ADR 007)      | Request metadata, IP, WAF events               | Global anycast (5+ AU PoPs)                   | [Cloudflare DPA](https://www.cloudflare.com/cloudflare-customer-dpa/) — SOC 2, ISO 27001, GDPR. $20/mo annual ($240/yr).                                                               |
| **Stripe**                  | Payments, Connect Express                                                                                       | ✅ Locked                | Card data, payout bank details                 | US (PCI-compliant; we never see card numbers) | [Stripe DPA](https://stripe.com/legal/dpa) — PCI Level 1, SOC 1 + 2                                                                                                                    |
| **Google (Gemini API)**     | LLM (task extraction, dispute mediation co-input, support RAG)                                                  | ✅ Locked                | Redacted user content                          | US/global                                     | [Google DPA](https://cloud.google.com/terms/data-processing-addendum) — zero-retention enabled on API                                                                                  |
| **Anthropic (Claude API)**  | LLM (dispute Tier-0 mediator, admin co-pilot brief)                                                             | ✅ Locked                | Redacted dispute evidence                      | US                                            | [Anthropic DPA](https://www.anthropic.com/legal/dpa) — zero-retention enabled                                                                                                          |
| **OpenAI (Embeddings API)** | Vector embeddings (text-embedding-3-small, 1536 dims)                                                           | ✅ Locked                | Task title + description + tasker bio (no PII) | US                                            | [OpenAI DPA](https://openai.com/policies/data-processing-addendum) — zero-retention on API tier                                                                                        |
| **Notifyre**                | SMS notifications (alphanumeric sender "JOBBEES")                                                               | ✅ Locked                | Phone numbers, SMS body                        | Australia                                     | AU-native vendor. Privacy Act + Spam Act compliant. Sender ID registration in progress (apply Sprint 0).                                                                               |
| **SendGrid**                | Transactional email                                                                                             | ✅ Locked                | Email addresses, email bodies                  | US/global                                     | [Twilio/SendGrid DPA](https://www.twilio.com/legal/data-protection-addendum) — SOC 2, GDPR                                                                                             |
| **FCM (Google)**            | Android push notifications                                                                                      | ✅ Locked                | Push tokens (anonymous device IDs)             | US/global                                     | Google DPA                                                                                                                                                                             |
| **APNS (Apple)**            | iOS push notifications                                                                                          | ✅ Locked                | Push tokens (anonymous device IDs)             | US/global                                     | Apple developer agreement                                                                                                                                                              |
| **Sentry**                  | Error tracking                                                                                                  | ✅ Locked                | Stack traces, request metadata (PII redacted)  | US                                            | [Sentry DPA](https://sentry.io/legal/dpa/) — SOC 2                                                                                                                                     |
| **GitHub**                  | Source code hosting + CI/CD (Actions)                                                                           | ✅ Locked                | Source code (not production data)              | US                                            | [GitHub DPA](https://github.com/customer-terms/github-data-protection-agreement) — SOC 2, GDPR                                                                                         |
| **Apple Developer Program** | App Store distribution + iOS signing                                                                            | ✅ Locked ($99/yr)       | App binary, store metadata                     | US                                            | Apple developer agreement                                                                                                                                                              |
| **Google Play Developer**   | Play Store distribution + Android signing                                                                       | ✅ Locked ($25 one-time) | App binary, store metadata                     | US                                            | Google Play Developer Distribution Agreement                                                                                                                                           |
| **(No identity vendor)**    | Tasker verification: handled by Stripe Connect KYC + ABR ABN check + manual per-category license review (admin) | ✅ Locked (ADR 005)      | n/a — no third-party identity vendor used      | n/a                                           | See ADR 005. Posters get a "Verified [Trade]" badge after admin cross-checks the license against the AU state register (e.g., NSW Fair Trading). No Didit / Stripe Identity / similar. |
| **Google Maps Platform**    | Geocoding + address autocomplete + map tiles                                                                    | ✅ Locked                | Place names + addresses queried (no user PII)  | US/global                                     | [Google Maps DPA](https://cloud.google.com/terms/data-processing-addendum). Chosen over Mapbox for AU coverage. Free $200 monthly credit; soft-launch volume well under cap.           |

## Pending decision (must resolve before respective sprint)

| Vendor (TBD)         | Service                                                                                                                | Status           | Decide by                     | Options under review                                                                                                                      |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------- | ---------------- | ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Phone OTP vendor** | SMS OTP for tasker phone verification (real provider — dev uses MockOtpService)                                        | 🟡 TBD (ADR 008) | Sprint 5 D1 (Mon 17 Aug 2026) | Firebase Phone Auth ($0.02/SMS pooled sender), Notifyre direct (~$0.06 AUD/SMS branded sender, recommended), Twilio Verify (~$0.05/verif) |
| **Analytics**        | Product event tracking                                                                                                 | 🟡 TBD           | Sprint 11 D1 (Mon 9 Nov 2026) | PostHog (open-source, self-hostable, AU friendly), Mixpanel (commercial)                                                                  |
| ~~**Geocoding**~~    | ✅ RESOLVED — Google Maps. Best AU coverage incl. regional NSW + inner-Sydney suburb mix. Moved to Locked vendors row. | n/a              | n/a                           | n/a                                                                                                                                       |

## Operationally needed (apply now, use later)

| Item                                               | When needed                                                                     | Lead time                                     | Status                                                                      |
| -------------------------------------------------- | ------------------------------------------------------------------------------- | --------------------------------------------- | --------------------------------------------------------------------------- |
| Google OAuth client ID                             | Sprint 2 D1 (Mon 6 Jul 2026)                                                    | instant                                       | TODO (create in existing Google Developer Console)                          |
| Apple OAuth client ID + Services ID                | Sprint 2 D1 (Apple Sign-in)                                                     | instant from existing Apple Developer account | TODO (create in existing Apple Developer account)                           |
| Notifyre alpha sender "JOBBEES"                    | Apply Sprint 1 D1 (Mon 22 Jun 2026) — needed for S5 OTP swap + S8 notifications | 5-7 business days                             | TODO                                                                        |
| ~~Stripe Connect Express application~~             | n/a                                                                             | n/a                                           | ✅ Stripe account exists; Connect Express integration uses existing account |
| ~~Apple Developer Program enrolment~~              | n/a                                                                             | n/a                                           | ✅ Enrolled                                                                 |
| ~~Google Play Developer account~~                  | n/a                                                                             | n/a                                           | ✅ Enrolled                                                                 |
| Tax advisor RFP (soft-engage, no commitment)       | Mid Sprint 5 (Fri 21 Aug 2026)                                                  | Shortlist + intro calls; no money committed   | TODO — high-priority                                                        |
| Tax advisor formal paid review                     | Sprint 11 (before Sprint 12 live-mode flip)                                     | Variable                                      | TODO                                                                        |
| Lawyer review of self-drafted ToS + Privacy Policy | Sprint 11 (Mon 9 Nov 2026)                                                      | 1-2 weeks                                     | TODO — draft self-served in Sprint 8 first                                  |

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
- `docs/adrs/005-kyc-strategy.md` (Stripe Connect + ABN + manual license review locked — no identity vendor)
- `docs/adrs/007-edge-security.md` (Cloudflare Pro chosen)
- `docs/adrs/008-otp-sms-strategy.md` (OTP vendor pending)
