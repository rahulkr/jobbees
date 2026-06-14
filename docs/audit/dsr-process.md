# Data Subject Request (DSR) Process

**Last reviewed:** TODO
**Owner:** TODO (Dev)

## Types of DSR

Under the Australian Privacy Act, users can request:

1. **Access** — copy of their personal information held
2. **Correction** — fix inaccurate information
3. **Deletion** — anonymisation pipeline (financial records retained 7 years)
4. **Withdrawal of consent** — for marketing, analytics, third-party sharing

## Receiving a request

| Channel                         | Where it lands                                                   |
| ------------------------------- | ---------------------------------------------------------------- |
| In-app (settings → privacy)     | `DsrRequest` table — triggers admin notification                 |
| Email to privacy@jobbees.com.au | Shared inbox → admin manually creates `DsrRequest` entry         |
| OAIC / regulator request        | Admin manually creates `DsrRequest` entry, flagged HIGH priority |

## SLA

| Request type       | Response within                                           |
| ------------------ | --------------------------------------------------------- |
| Access             | 30 days                                                   |
| Correction         | 30 days                                                   |
| Deletion           | 30 days (anonymisation), 90 days (full per-policy review) |
| Consent withdrawal | Immediate (system-level)                                  |

## Workflow

1. User submits request → `DsrRequest` row created with type, requester ID, status `RECEIVED`
2. Admin reviews in `/admin/audit/dsr` queue → verifies identity (already authenticated, so usually trivial)
3. Admin clicks "Process" → backend triggers the relevant pipeline:
   - **Access:** generates a JSON export of all data tied to the user; signed download link sent via email
   - **Correction:** admin manually edits the disputed field; audit log entry
   - **Deletion:** anonymisation pipeline runs (see `data-retention-policy.md`)
   - **Consent withdrawal:** `ConsentRecord` entry with `revokedAt = now`; downstream systems honour the new consent state
4. Status updated to `COMPLETED`; user notified

## Data included in an Access request

| Source           | What's included                                                        |
| ---------------- | ---------------------------------------------------------------------- |
| User profile     | Name, email, phone, address, KYC status, role                          |
| Tasker profile   | Bio, skills, hourly rate, completion stats                             |
| Jobs posted      | Title, description, status, budget, photos                             |
| Offers submitted | Amount, message, status                                                |
| Messages         | Threads, message content (own messages only)                           |
| Reviews          | Reviews authored, reviews received                                     |
| Disputes         | Disputes involved in (anonymised counterparty if they've also deleted) |
| Payments         | Payment history (amount, date, status, NOT card number)                |
| Tax records      | Tax invoices + RCTIs                                                   |
| Consent log      | All ConsentRecord entries                                              |
| Audit log        | Sensitive actions on this user (suspension events, etc.)               |

## Data NOT included

- Other users' personal information (counterparty PII redacted)
- Internal moderation notes
- LLM evaluation results
- Information protected by legal privilege

## Verification

User must be authenticated to submit a DSR. If the user is locked out, they verify via email + phone OTP.

For non-authenticated requests (e.g., the user's account was deleted but they want a copy), require government ID verification before processing.

## Audit log

Every DSR action is logged:

- Request received (who, when, type)
- Admin who processed it
- What data was returned / edited / deleted
- Timestamp of completion

## See also

- `data-retention-policy.md`
- `data-classification-policy.md`
- `australian-compliance.md`
- `audit-log-policy.md`
