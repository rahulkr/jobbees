# Data Classification Policy

**Last reviewed:** TODO
**Owner:** TODO (Client + Dev)

## Classifications

| Class                      | Examples                                                                                            | Storage requirements                                                                                                  |
| -------------------------- | --------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **PII (Personal)**         | Name, email, phone, address, profile photo, KYC documents, IP address, device ID                    | Encrypted at rest + in transit. Access logged. Anonymisable on DSR request.                                           |
| **Financial**              | Payment amounts, Stripe customer ID, Stripe Connect account ID, payout history, tax invoices, RCTIs | Encrypted at rest + in transit. **Retained 7 years per ATO** even after user deletion. Anonymised at user-link level. |
| **Operational**            | Job content, offers, messages, reviews, disputes                                                    | Encrypted at rest + in transit. Soft-deleted with user. Retained 2 years for support purposes.                        |
| **Anonymous / Aggregated** | Analytics events (no user ID), counts, metrics                                                      | No encryption requirement. Retained indefinitely.                                                                     |
| **Secret**                 | Passwords (hashed), JWT secrets, Stripe keys, LLM API keys, DB connection strings                   | Hashed (passwords) or encrypted in Azure Key Vault. Never logged. Never sent to LLMs.                                 |

## Classification by table

TODO: map every Postgres table to a classification. Format:

| Table         | Classification    | Notes                                     |
| ------------- | ----------------- | ----------------------------------------- |
| User          | PII               | Anonymised on DSR delete                  |
| Payment       | Financial         | Retained 7 years                          |
| TaxInvoice    | Financial         | Retained 7 years                          |
| Rcti          | Financial         | Retained 7 years                          |
| Job           | Operational       | Soft-deleted, retained 2 years            |
| Offer         | Operational       | Cascaded delete with Job                  |
| Review        | Operational       | Anonymised on user delete                 |
| Dispute       | Operational + PII | Anonymised on user delete                 |
| AuditLog      | Operational       | Retained 7 years (audit obligation)       |
| ConsentRecord | Operational       | Retained 7 years (Privacy Act obligation) |

## Handling rules

- **PII** must be redacted before any external LLM call (Gemini, Claude, OpenAI).
- **Financial** records are never hard-deleted. Anonymisation = swap user_id reference with a UUID, NULL out PII fields on the linked User.
- **Operational** records are soft-deleted via `deletedAt` on the relevant tables.
- **Secrets** are never committed to git (gitleaks pre-commit blocks). Production secrets only in Azure Key Vault.

## See also

- `data-retention-policy.md`
- `encryption-policy.md`
- `australian-compliance.md`
