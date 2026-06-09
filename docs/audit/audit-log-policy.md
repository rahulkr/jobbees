# Audit Log Policy

**Last reviewed:** TODO
**Owner:** TODO (Dev)

## What gets logged

Every sensitive write produces an `AuditLog` row:

| Action                       | Resource    | Notes                                |
| ---------------------------- | ----------- | ------------------------------------ |
| `user.suspend`               | User        | Includes reason, actor, IP           |
| `user.unsuspend`             | User        |                                      |
| `user.delete`                | User        | Triggered by DSR                     |
| `user.anonymise`             | User        | Anonymisation pipeline completion    |
| `kyc.override`               | User        | Manual KYC approval/reject by admin  |
| `payment.refund`             | Payment     | Amount, reason                       |
| `payment.partial_refund`     | Payment     | Amount, reason                       |
| `payment.manual_capture`     | Payment     | Admin manually capturing held funds  |
| `payment.void`               | Payment     |                                      |
| `dispute.resolve`            | Dispute     | Resolution type, admin who decided   |
| `dispute.tier0.proposal`     | Dispute     | What Tier-0 proposed                 |
| `dispute.tier0.accept`       | Dispute     | Who accepted (poster/tasker/both)    |
| `dispute.escalate`           | Dispute     | Reason for escalation                |
| `task.force_cancel`          | Task        | Admin force-cancellation             |
| `category.change_type`       | Category    | TRANSACTIONAL ↔ LEAD swap (post-MVP) |
| `category.commission_change` | Category    | Platform fee change                  |
| `config.change`              | Config      | Any platform-level config change     |
| `dsr.request`                | User        | DSR request received                 |
| `dsr.complete`               | User        | DSR completed                        |
| `admin.login`                | Admin       | Successful login + 2FA               |
| `admin.login_failed`         | Admin       | Failed login attempt (with reason)   |
| `admin.role_change`          | Admin       | Role escalation/de-escalation        |
| `consent.grant`              | User        | New consent record                   |
| `consent.revoke`             | User        | Withdrawn consent                    |
| `feature_flag.toggle`        | FeatureFlag | Production flag toggle               |

## Schema

```prisma
model AuditLog {
  id            String   @id
  actorId       String?
  action        String
  resourceType  String
  resourceId    String
  diffJson      Json?
  ipAddress     String?
  userAgent     String?
  createdAt     DateTime @default(now())

  @@index([resourceType, resourceId, createdAt])
  @@index([actorId, createdAt])
  @@index([action, createdAt])
}
```

## Retention

7 years. Aligns with ATO retention for financial records. Hard-deleted after 7 years via annual cron.

## Access

- Read access: ADMIN role
- Write access: programmatic only — no human writes ever
- The audit log itself is never modified or deleted (except by the 7-year retention cron)

## Querying

Admin UI: `/admin/audit/log` with filters (action, actor, resource, date range)

Direct database queries are forbidden in production (no human access to prod DB).

## Tamper detection

TODO post-MVP: append-only writes via Postgres trigger + hash chain for tamper detection.

## What's NOT logged

- Routine reads (page views, list queries)
- User-facing reads of their own data
- Health checks
- LLM call metadata (separate cost telemetry log, not audit log)

## See also

- `access-control-policy.md`
- `change-management.md`
- `dsr-process.md`
