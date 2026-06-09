# Australian Compliance

**Last reviewed:** TODO
**Owner:** TODO (Client + Australian counsel + Australian tax advisor + Dev)

Maps every Australian legal/regulatory obligation to system behaviour. Reviewed annually + after any relevant law change.

## Privacy Act 1988 (Cth)

| Australian Privacy Principle (APP) | System implementation |
| --- | --- |
| APP 1 — Open and transparent management | Privacy Policy published, kept in sync via `privacy-policy.md` mapping |
| APP 2 — Anonymity / pseudonymity | Posters can use display names; full name required only for KYC verification |
| APP 3 — Collection of solicited personal information | Only collect what's necessary for marketplace function; documented in `data-classification-policy.md` |
| APP 4 — Dealing with unsolicited information | Process to delete unsolicited personal info on receipt (admin queue) |
| APP 5 — Notification of collection | Signup flow shows what data is collected + why |
| APP 6 — Use or disclosure | Only for marketplace purposes + with consent for marketing |
| APP 7 — Direct marketing | Granular opt-out per channel; honoured server-side |
| APP 8 — Cross-border disclosure | Vendor list + DPAs cover Stripe, Gemini, Anthropic, etc. |
| APP 9 — Adoption / use of gov identifiers | Not collected (no TFN, ABN handled separately as business info) |
| APP 10 — Quality of personal info | DSR correction endpoint |
| APP 11 — Security of personal info | `encryption-policy.md`, `access-control-policy.md`, `vulnerability-management.md` |
| APP 12 — Access to personal info | DSR access endpoint |
| APP 13 — Correction of personal info | DSR correction endpoint |

## Notifiable Data Breaches scheme

See `incident-response-plan.md` — 30-day assessment, OAIC notification for eligible breaches.

## Tax obligations (ATO + GST)

| Obligation | System implementation |
| --- | --- |
| GST registration | TODO: client to register platform once turnover hits $75k AUD/year |
| GST collection (10%) | On platform fee only; calculated by `GstService` |
| Tax invoices (poster side) | Generated on every captured payment |
| RCTI (Recipient-Created Tax Invoice) | For taskers without ABN; consent required at signup; generated on payout |
| ABN collection + validation | At tasker signup; ABR lookup; quarterly re-check |
| **ATO Sharing Economy Reporting Regime** | Monthly export to ATO Online Services; fields per ATO spec |
| BAS (Business Activity Statement) | TODO: client's accountant handles; we provide the data |
| Income tax compliance | TODO: client's accountant; data export via admin reports |

**Tax advisor sign-off required before any tax-related code merges.** Specifically:
- GST calculation logic
- RCTI generation + agreement wording
- ATO export field schema

## Stripe Connect / Australian payments

| Requirement | System implementation |
| --- | --- |
| AUSTRAC registration | TODO: client to assess (typically not required for marketplaces under threshold) |
| Stripe Connect onboarding | Connect Express with bundled KYC (Stripe Identity) + bank verification |
| KYC for taskers | Required before payout (Stripe Identity) |
| KYC for posters | Required for >$1000 single transactions (TODO: confirm threshold with client) |
| Anti-money laundering | Stripe handles transaction monitoring; we surface flagged transactions to admin |

## Spam Act 2003

| Requirement | System implementation |
| --- | --- |
| Consent for marketing messages | Granular opt-in at signup + settings |
| Functional unsubscribe in every commercial electronic message | Unsubscribe token endpoint on every marketing email |
| Sender identification | "From" header always includes JOBBees + ABN |
| SMS STOP keyword | Honoured server-side |

## Consumer Law (ACL)

| Requirement | System implementation |
| --- | --- |
| Statutory consumer guarantees | TODO: review T&Cs with counsel; can't exclude statutory rights |
| Misleading and deceptive conduct | Marketing copy review (client + counsel) |
| Dispute resolution | Internal dispute mediator (Tier-0) + escalation to admin; escalation to ACCC / state fair trading available |

## Accessibility (Disability Discrimination Act 1992)

| Requirement | System implementation |
| --- | --- |
| Reasonable accessibility | WCAG 2.1 AA target (basics at MVP; full audit client-side post-launch) |

## Children

| Requirement | System implementation |
| --- | --- |
| No under-18 users | Age check at signup (TODO) |

## Annual review checklist

Update this doc when:
- A new Australian law / regulation comes into force
- A new vendor is added (DPA review)
- The platform expands to a new state with state-specific rules
- The tax advisor flags a change

## See also

- `privacy-policy.md`
- `data-retention-policy.md`
- `dsr-process.md`
- `vendor-list.md`
- `incident-response-plan.md`
- `.claude/skills/au-tax/SKILL.md`
