# Runbooks

Operational procedures for common tasks and incidents. Fill in as the system grows.

## Planned runbooks

| File | Purpose |
| --- | --- |
| `local-development.md` | Setting up the repo on a fresh machine (covered in repo README for now) |
| `deploying.md` | Deploy procedure for staging + production |
| `restoring-from-backup.md` | Step-by-step Postgres restore (see also `docs/audit/backup-recovery-procedure.md`) |
| `rotating-secrets.md` | Stripe keys, JWT secrets, LLM API keys |
| `responding-to-stripe-outage.md` | What to do when Stripe is down |
| `handling-data-breach.md` | Incident response detail (see also `docs/audit/incident-response-plan.md`) |
| `debugging-payments.md` | Common payment edge cases + Stripe Dashboard tools |
| `debugging-llm-costs.md` | Investigating cost spikes |
| `seeding-launch-city.md` | Synthetic supply onboarding for a new launch geography |

Don't pre-write all of these. Write them when you do the thing for the first time. The notes-from-doing become the runbook.
