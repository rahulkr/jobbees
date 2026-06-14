# Business Continuity + Disaster Recovery Plan

**Last reviewed:** TODO
**Owner:** TODO (Client + Dev)

## Continuity objectives

| Service                                        | Acceptable downtime per month | Notes                                                                                       |
| ---------------------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------- |
| Marketplace (post job, offer, accept, message) | 4 hours (99.5% uptime)        | MVP target. Industry floor for payments is 99.9% — see roadmap                              |
| Payment processing                             | 1 hour                        | Stripe handles most of the availability; we just can't process new captures during downtime |
| Admin operations                               | 8 hours                       | Lower priority; manual workarounds available                                                |
| Public web (SEO)                               | 4 hours                       | Marketing impact; cached pages on CDN mitigate                                              |

## Disaster scenarios

| Scenario                                    | Likelihood | Impact                          | RPO                      | RTO                          |
| ------------------------------------------- | ---------- | ------------------------------- | ------------------------ | ---------------------------- |
| App Service single-instance failure         | Medium     | Low                             | 0                        | 1-5 min (auto-restart)       |
| App Service region failure (Australia East) | Low        | Critical                        | 5 min                    | 4-8 hours (manual failover)  |
| Postgres failure                            | Low        | Critical                        | 5 min                    | 1-4 hours (PITR or failover) |
| Logical data corruption (bad migration)     | Medium     | High                            | 7 days (pg_dump cadence) | 2-4 hours                    |
| Stripe outage                               | Low        | Critical (no payments possible) | 0                        | Wait for Stripe              |
| Azure-wide outage                           | Very low   | Critical                        | TBD                      | TBD                          |
| Compromised admin credentials               | Medium     | High                            | 0                        | 1 hour (rotate + audit)      |
| Source code loss                            | Very low   | Medium                          | 0                        | 1 hour (GitHub mirror)       |

## Failover procedures

### App Service failover

1. Azure Front Door routes to healthy regional instance (automatic)
2. If primary region fully down: manual DNS swap to secondary deployment
3. Monitor Sentry + App Insights for application errors

### Postgres failover

1. Azure Database for PostgreSQL Flexible Server with HA enabled — automatic failover within region
2. Cross-region failover requires manual restore from geo-redundant backup (see `backup-recovery-procedure.md`)

### Compromised credentials

1. Rotate all secrets in Azure Key Vault
2. Force re-authentication for all admins
3. Invalidate all refresh tokens
4. Review audit log for the time window of compromise
5. Notify affected users if data was accessed
6. OAIC notification if eligible breach (see `incident-response-plan.md`)

## Status page

TODO: set up a Statuspage.io or Azure-native status page at `status.jobbees.com.au` for external communication during incidents.

## Communication during outage

- Internal: incident channel (Slack/Teams)
- Active users: in-app banner via feature flag (if backend is partially up)
- Public: status page + email blast to active users for incidents > 1 hour

## Knowledge continuity

Mitigations against knowledge loss:

- All architectural knowledge documented in this repo (PROJECT_CONTEXT.md, ADRs, audit docs, CLAUDE.md files)
- All credentials in Azure Key Vault with client/owner backup access
- GitHub repository access controlled at the org level, not tied to any individual
- Stripe / Azure / vendor accounts owned by the company entity, not by any individual contributor
- Quarterly knowledge-handover review (TODO: schedule)

## See also

- `backup-recovery-procedure.md`
- `incident-response-plan.md`
- `access-control-policy.md`
