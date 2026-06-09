# Incident Response Plan

**Last reviewed:** TODO
**Owner:** TODO (Client + Dev)

## Severity classification

| Severity | Definition | Response time | Communication |
| --- | --- | --- | --- |
| **P0 — Critical** | Payment failure, data breach, full outage, security compromise | Immediate (within 15 min) | Internal: page lead dev + product owner. External: status page + email to active users |
| **P1 — High** | Partial outage, degraded performance, single payment failure | Within 1 hour | Internal: notify dev + client |
| **P2 — Medium** | Bug affecting some users, slow response time | Same business day | Internal: track in issue tracker |
| **P3 — Low** | Cosmetic, minor UX, single-user issue | Within 1 week | Internal only |

## Notifiable data breach (Australian Privacy Act)

Under the Notifiable Data Breaches scheme, if there's an "eligible data breach" (unauthorised access/disclosure of personal info likely to cause serious harm), we must:
1. Assess within 30 days
2. If eligible, notify OAIC and affected individuals as soon as practicable

**Triggers for assessment:**
- Confirmed unauthorised access to the database
- Stolen credentials with access to user data
- Lost device with access to production
- Insider misuse of access privileges
- Successful phishing of admin account

## Roles and responsibilities

TODO: assign named individuals:
- **Incident commander** — coordinates response
- **Technical lead** — investigates, contains, recovers
- **Communications lead** — internal + external messaging
- **Legal / compliance** — OAIC notification, regulator communication

## Response playbook

### 1. Detect
- Sentry / App Insights alerts
- Failed health checks
- User reports via support
- Security scanner alerts (Trivy, CodeQL)

### 2. Triage (within 15 min for P0)
- Confirm reality (real incident vs false positive)
- Classify severity
- Page incident commander
- Open incident channel (Slack / Teams)

### 3. Contain (within 1 hour for P0)
- Stop the bleeding — disable affected feature, revert deploy, rotate compromised credentials
- Preserve evidence (logs, audit log entries, suspect user accounts)
- Don't destroy evidence trying to "fix" things

### 4. Investigate
- Root cause analysis
- Determine scope (who's affected, what data, how long)
- Document timeline

### 5. Recover
- Apply permanent fix
- Restore from backup if needed (see `backup-recovery-procedure.md`)
- Re-enable disabled features

### 6. Communicate
- Internal: post-mortem within 5 business days
- External (if user-facing): status page update during incident; email to affected users if eligible breach
- Regulator (if eligible breach): OAIC notification within 30 days

### 7. Post-mortem
- Blameless write-up: what happened, why, what we'll change
- Action items with owners + dates
- Update this playbook if a new failure mode emerged

## Communication templates

TODO: pre-draft templates for:
- Status page update (incident open / resolved)
- Affected-user email (eligible data breach)
- OAIC notification format
- Internal post-mortem template

## Contacts

TODO: list with phone numbers
- Incident commander (primary + backup)
- Technical lead
- Communications lead
- Legal counsel
- OAIC (Office of the Australian Information Commissioner)
- Stripe support
- Azure support

## See also

- `vulnerability-management.md`
- `backup-recovery-procedure.md`
- `australian-compliance.md`
