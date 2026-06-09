# IT Audit Documentation

This folder contains the documents an IT auditor will expect to see for a payment-handling Australian marketplace.

Each file is a **template** at this stage. Fill them in as features ship — most are 1–2 hour docs once the underlying feature exists. By launch, they're all populated and the auditor's request becomes "send me the docs/audit folder".

## Index

| # | Document | Owner | Fill when |
| --- | --- | --- | --- |
| 1 | [architecture-overview.md](./architecture-overview.md) | Dev | After first deploy to staging |
| 2 | [data-flow-diagram.md](./data-flow-diagram.md) | Dev | After payment + KYC modules ship |
| 3 | [data-classification-policy.md](./data-classification-policy.md) | Client + Dev | Phase 1 |
| 4 | [data-retention-policy.md](./data-retention-policy.md) | Client + Dev | Phase 1 |
| 5 | [encryption-policy.md](./encryption-policy.md) | Dev | After Key Vault setup |
| 6 | [access-control-policy.md](./access-control-policy.md) | Client | Phase 1 |
| 7 | [backup-recovery-procedure.md](./backup-recovery-procedure.md) | Dev | After Postgres setup |
| 8 | [incident-response-plan.md](./incident-response-plan.md) | Client + Dev | Pre-launch |
| 9 | [vulnerability-management.md](./vulnerability-management.md) | Dev | After CI setup |
| 10 | [change-management.md](./change-management.md) | Dev | Phase 1 |
| 11 | [vendor-list.md](./vendor-list.md) | Dev | Phase 1 |
| 12 | [privacy-policy.md](./privacy-policy.md) | Client + lawyer | Pre-launch |
| 13 | [dsr-process.md](./dsr-process.md) | Dev | After DSR endpoints ship |
| 14 | [audit-log-policy.md](./audit-log-policy.md) | Dev | After audit log table exists |
| 15 | [bcp-dr-plan.md](./bcp-dr-plan.md) | Client + Dev | Pre-launch |
| 16 | [secure-sdlc.md](./secure-sdlc.md) | Dev | Phase 1 |
| 17 | [australian-compliance.md](./australian-compliance.md) | Client + tax advisor + Dev | Pre-launch |

## When the auditor arrives

1. Send them this folder
2. Walk them through the architecture overview and data flow diagram
3. Show them the security tooling output (CodeQL, Semgrep, Trivy, Sentry reports)
4. Provide the audit log access (read-only admin role)

## Update cadence

- Most docs are updated when the underlying feature changes
- `australian-compliance.md` reviewed annually
- `vendor-list.md` updated when a vendor is added or removed
- `incident-response-plan.md` reviewed quarterly + after any actual incident
