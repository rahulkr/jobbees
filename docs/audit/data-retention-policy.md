# Data Retention Policy

**Last reviewed:** TODO
**Owner:** TODO (Client + Dev)

## Retention periods by table

| Table                  | Retention period                                      | Trigger         | Action on retention end                         |
| ---------------------- | ----------------------------------------------------- | --------------- | ----------------------------------------------- |
| User                   | Indefinite (soft delete on DSR)                       | DSR request     | Anonymise PII fields; keep row for FK integrity |
| TaskerProfile          | Indefinite (soft delete on DSR)                       | DSR request     | Anonymise PII fields                            |
| Payment                | 7 years from creation                                 | Annual cron     | Anonymise user link, keep amounts + dates       |
| TaxInvoice             | 7 years from creation                                 | Annual cron     | Anonymise user link, keep invoice content       |
| Rcti                   | 7 years from creation                                 | Annual cron     | Anonymise user link, keep RCTI content          |
| Task                   | 2 years from `completedAt` or `cancelledAt`           | Quarterly cron  | Hard delete                                     |
| Bid                    | Cascade with Task                                     | —               | Cascade                                         |
| Review                 | Anonymise on user delete; 2 years for the linked task | Cascade         | Anonymise reviewer name to "Former member"      |
| Dispute                | 2 years from `resolvedAt`                             | Quarterly cron  | Anonymise PII, keep resolution record           |
| Thread + Message       | 2 years from last message                             | Quarterly cron  | Hard delete                                     |
| AuditLog               | 7 years from creation                                 | Annual cron     | Hard delete (oldest first)                      |
| OtpRecord              | 24 hours                                              | Continuous cron | Hard delete                                     |
| SessionToken           | 30 days or revocation                                 | Continuous cron | Hard delete                                     |
| IdempotencyKey (Redis) | 24 hours                                              | Redis TTL       | Auto-expire                                     |
| ConsentRecord          | 7 years (Privacy Act)                                 | Annual cron     | Hard delete (oldest first)                      |

## DSR (Data Subject Request) handling

A user requests deletion → triggers anonymisation pipeline:

1. Mark User as `deletedAt = now`, `anonymisedAt = now`
2. Replace `firstName`, `lastName`, `email`, `phone`, `defaultAddress` with `[deleted-user-{uuid}]` or NULL
3. Anonymise the linked Tasker bio, profile photo URL
4. Keep Payment, TaxInvoice, RCTI records — they retain the (now anonymised) user link
5. Anonymise reviewer names on Reviews authored by this user → "Former member"
6. Cascade delete: Bids, Threads/Messages, Disputes (anonymised)
7. Log the DSR completion in AuditLog

## See also

- `dsr-process.md`
- `australian-compliance.md`
- `data-classification-policy.md`
