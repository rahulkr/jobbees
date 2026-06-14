# Backup and Recovery Procedure

**Last reviewed:** TODO
**Owner:** TODO (Dev)

## Backup strategy

| Data                                       | Method                                         | Frequency                          | Retention  | Where                        |
| ------------------------------------------ | ---------------------------------------------- | ---------------------------------- | ---------- | ---------------------------- |
| Postgres (production)                      | Azure managed backup                           | Continuous (point-in-time restore) | 35 days    | Azure-managed, geo-redundant |
| Postgres (logical pg_dump)                 | GitHub Actions cron                            | Weekly                             | 12 weeks   | Azure Blob (separate region) |
| Azure Blob (media)                         | Soft delete + versioning                       | Continuous                         | 30 days    | Azure-managed                |
| Configuration (Terraform state, Key Vault) | Azure-managed redundancy                       | Continuous                         | Indefinite | Azure                        |
| Source code (GitHub)                       | GitHub mirror + occasional `git bundle` export | Continuous + monthly               | Indefinite | GitHub + Azure Blob          |

## RPO / RTO targets

| Scenario                                      | RPO (max data loss)      | RTO (max downtime)                              |
| --------------------------------------------- | ------------------------ | ----------------------------------------------- |
| Single-region Postgres failure                | 5 minutes                | 1 hour (Azure failover)                         |
| Logical data corruption (e.g., bad migration) | 7 days (pg_dump cadence) | 2-4 hours (manual restore)                      |
| Full Azure region outage                      | 1 hour                   | 4-8 hours (manual failover to secondary region) |
| Source code loss                              | n/a                      | n/a (multiple copies)                           |

These targets are MVP-grade. Tighter RPO/RTO requires multi-region active-active, which is POST.

## Restore procedure (Postgres)

### Scenario 1: Point-in-time restore (recent corruption)

1. Open Azure Portal → Database → Restore
2. Select target time (last 35 days)
3. Restore to a new server (`jobbees-restore-YYYYMMDD`)
4. Verify data integrity on restored server
5. Swap connection string in Key Vault → restart App Service
6. Decommission old server after 7 days

### Scenario 2: Logical restore from pg_dump

1. Download latest `pg_dump_YYYYMMDD.sql.gz` from Azure Blob
2. Spin up a fresh Postgres instance (matching schema version)
3. `psql -d jobbees < pg_dump.sql`
4. Verify row counts in 5 critical tables (User, Job, Payment, TaxInvoice, AuditLog)
5. Swap connection string → restart App Service

## Quarterly restore drill

TODO: automate via GitHub Actions:

1. Pull latest `pg_dump` from Blob
2. Spin up a temporary Postgres
3. Restore + run smoke test queries
4. Email pass/fail to dev team

Skipping the drill is a common cause of "we have backups but can't actually restore". Drill is mandatory.

## What's NOT backed up

- Redis (cache only — losing it just means cache miss + slower next request)
- Local dev databases (intentionally ephemeral)
- Sentry / App Insights logs (provider-managed retention)

## See also

- `bcp-dr-plan.md`
- `incident-response-plan.md`
