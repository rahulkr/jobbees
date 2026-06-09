# Change Management

**Last reviewed:** TODO
**Owner:** TODO (Dev)

## Workflow

All changes flow through git + GitHub PR. No direct production access; no manual database writes.

1. Pick a work item from the team's scope tracker / issue board
2. Create branch `feat/<ID>-<short-name>` from `main`
3. Implement; commit with `feat(<ID>): <description>` messages
4. Push, open PR
5. CI runs: lint, typecheck, tests, security scans (CodeQL, Semgrep, Trivy, gitleaks)
6. Self-review your own diff (or get peer review if available); verify CI is green
7. Run `security-review` skill if PR touches auth, payments, or PII
8. Merge to `main`
9. CI auto-deploys to staging
10. Verify on staging (smoke test critical paths)
11. Promote to production via manual approval gate

## Branch protection on `main`

TODO: enforce in GitHub repo settings:

- Require PR before merge
- Require status checks: lint, typecheck, test, codeql, trivy, gitleaks
- Require linear history (squash merge)
- Block force push
- Block deletion

## Deploy approval gates

| Environment | Approval                | Trigger                                    |
| ----------- | ----------------------- | ------------------------------------------ |
| Dev (local) | n/a                     | `pnpm dev` on developer machine            |
| Staging     | Auto on merge to `main` | GitHub Actions                             |
| Production  | Manual approval in CI   | GitHub Actions environment protection rule |

## Database migration handling

- `prisma migrate dev` for local development (generates migration files)
- Migration files committed alongside the code change
- CI runs `prisma migrate deploy` on staging + production deploys
- **App startup does not run migrations.** Migrations are an explicit CI step.
- Destructive changes (column drop, table drop) require two-phase deploy: (1) add new + copy data + deploy, (2) drop old + deploy

## Rollback procedure

| Type                               | Rollback method                                        |
| ---------------------------------- | ------------------------------------------------------ |
| Code only                          | Revert PR, re-deploy via standard CI/CD                |
| Schema additive (new table/column) | Code revert sufficient — old code ignores new columns  |
| Schema destructive                 | Restore from backup OR roll forward with new migration |
| Stripe configuration               | Manual via Stripe dashboard; document in audit log     |
| Azure infrastructure               | `terraform apply` with previous state                  |

## Audit trail

- Every commit → `git log` (immutable)
- Every PR → GitHub PR history (immutable)
- Every deploy → GitHub Actions log (retained 90 days; archived to Azure Blob for 7 years)
- Every prod change touching user/payment data → AuditLog table entry

## Emergency change (hotfix) process

1. Branch `hotfix/<ID>-<short-name>` from `main`
2. Skip the usual full CI suite if needed — but security scans (gitleaks, CodeQL critical) are non-negotiable
3. Deploy directly to production via manual gate
4. Backfill: open a regular PR to merge the hotfix into the normal branch
5. Post-mortem within 5 days if the hotfix addressed a P0/P1 incident

## See also

- `secure-sdlc.md`
- `incident-response-plan.md`
- `audit-log-policy.md`
