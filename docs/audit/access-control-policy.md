# Access Control Policy

**Last reviewed:** TODO
**Owner:** TODO (Client)

## User-level roles (in-app)

| Role | Capabilities |
| --- | --- |
| POSTER | Post tasks, accept bids, pay, review |
| TASKER | Bid on tasks, deliver work, get paid, review |
| ADMIN | Moderate content, handle disputes, issue refunds, KYC overrides — see admin role detail |
| SUPER_ADMIN | Everything ADMIN + manage admins + change configuration |

## Admin-level access

| Resource | Role required | Audit logged |
| --- | --- | --- |
| View user details | ADMIN | Yes |
| Suspend / ban user | ADMIN | Yes |
| Manual KYC override | ADMIN | Yes |
| Refund payment | ADMIN | Yes |
| Manually capture payment | ADMIN | Yes |
| Resolve dispute | ADMIN | Yes |
| Edit FAQ / help articles | ADMIN | Yes |
| Edit category taxonomy | ADMIN | Yes |
| Change platform fees | SUPER_ADMIN | Yes |
| Change cancellation matrix | SUPER_ADMIN | Yes |
| Change Tier-0 dispute threshold | SUPER_ADMIN | Yes |
| Manage admin users | SUPER_ADMIN | Yes |
| Read audit log | ADMIN (read-only) | n/a (audit log itself) |

## Infrastructure-level access

| Resource | Who has access | How |
| --- | --- | --- |
| Production Azure subscription | TODO: list named individuals | Azure AD with MFA |
| Production database (read) | TODO | Azure AD + Postgres-level grant |
| Production database (write) | NOBODY direct — only via NestJS API | n/a |
| Stripe live dashboard | TODO | Stripe team accounts with 2FA |
| Sentry | TODO | Sentry team |
| Azure Key Vault | TODO: app identity only for read; named admins for write | Managed identity + Azure RBAC |
| GitHub repository | TODO: named contributors | GitHub team with branch protection |

## Authentication requirements

- **End users:** email + password OR Google/Apple OAuth; phone OTP for taskers
- **Admins:** email + password + **mandatory TOTP 2FA** for every login; 8-hour session, 30-min idle timeout
- **Infrastructure:** Azure AD with MFA on every named individual

## Joiners, movers, leavers process

TODO: client-side procedure for:
- New admin onboarding (account creation, role assignment, 2FA setup)
- Role changes (audit log entry, principle of least privilege)
- Offboarding (revoke all access within 24h of departure)
- Quarterly access review

## See also

- `change-management.md`
- `incident-response-plan.md`
- `audit-log-policy.md`
