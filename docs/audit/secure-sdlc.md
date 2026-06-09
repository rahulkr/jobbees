# Secure SDLC

**Last reviewed:** TODO
**Owner:** TODO (Dev)

## Phases

### 1. Plan

- Pick a work item from the scope tracker / issue board
- For non-trivial work, use Claude Code plan mode before coding
- Identify if work touches: auth, payments, PII, KYC, AI/LLM, admin actions — these are high-risk paths

### 2. Develop

- Branch per work item
- CLAUDE.md files auto-load context for the AI assistant
- Local pre-commit hooks (lefthook): gitleaks, eslint, prettier, typecheck
- Custom Claude Code skills loaded for relevant domains (stripe-payment, au-tax, pgvector-match, tier0-dispute)
- All payment / tax / PII code: manual review of every AI-generated line

### 3. Test

- Unit tests for services
- E2E tests for critical flows (signup, post task, bid, pay, complete, dispute, refund)
- Stripe test mode keys; never live keys in tests
- Tax test suite with ATO-validated fixtures (`pnpm test:tax`)
- Tier-0 mediator eval suite with hand-labelled disputes

### 4. Review (security-specific)

- PR opened — CI runs full security suite: CodeQL, Semgrep, Trivy, gitleaks
- For auth / payments / PII PRs: run `security-review` skill in Claude Code before merging
- Manual review of the diff before merging — the diff view catches surprises that tests miss

### 5. Deploy

- Merge to `main` → CI deploys to staging
- Smoke test on staging (manual checklist for critical flows)
- Promote to production via manual approval gate

### 6. Operate

- Monitor Sentry + App Insights for new errors
- Daily check of audit log for unusual patterns
- Weekly check of LLM cost telemetry
- Quarterly: pen-test, restore drill, access review

### 7. Retire

- When a feature is removed: code deletion, schema migration, vendor de-integration, vendor list update, privacy policy update

## High-risk paths (extra scrutiny)

These get extra review and the `security-review` skill is mandatory:

- **Authentication** — JWT signing, password handling, OAuth flows, biometric token exchange
- **Authorization** — role checks, permission decorators, admin gates
- **Payments** — Stripe SDK calls, payment state machine, idempotency, refund logic
- **Tax** — GST, RCTI, ATO export — additionally requires tax advisor sign-off
- **PII handling** — anything that touches User PII, especially before sending to LLMs
- **DSR / Privacy** — anonymisation pipeline, deletion cascade
- **Audit log** — write paths (no one should be able to skip an audit log entry)
- **File uploads** — image moderation, virus scan, EXIF stripping for PII
- **Webhook handlers** — Stripe, third-party webhooks; signature verification mandatory
- **LLM call sites** — PII redaction before send, cost telemetry, rate limits

## Tooling

| Stage                | Tool                                                                    |
| -------------------- | ----------------------------------------------------------------------- |
| Pre-commit           | lefthook, gitleaks, eslint, prettier, typecheck                         |
| PR                   | GitHub Actions: lint, test, typecheck, CodeQL, Semgrep, Trivy, gitleaks |
| AI assistance        | Claude Code with custom skills + `security-review`                      |
| Manual review        | Self-review diff in GitHub PR view                                      |
| Staging verification | Smoke test checklist                                                    |
| Production deploy    | Manual approval gate                                                    |
| Monitoring           | Sentry + App Insights + audit log                                       |

## Common security pitfalls (and how the SDLC prevents them)

| Pitfall                  | Prevention                                                               |
| ------------------------ | ------------------------------------------------------------------------ |
| Secrets in code          | Pre-commit gitleaks + CI gitleaks                                        |
| Unvalidated input        | class-validator DTOs on every endpoint, schema rejection                 |
| SQL injection            | Prisma's parameterised queries; `$queryRaw` uses template-tag form only  |
| XSS in admin/web         | React's default escaping + Content Security Policy headers               |
| Insecure deserialisation | Zod schemas on all external input                                        |
| Missing rate limits      | Per-user rate limit middleware on all mutating + AI endpoints            |
| Missing idempotency      | IdempotencyInterceptor required on all mutating endpoints                |
| Skipped audit logging    | AuditLogService injection in every admin action; lint rule blocks bypass |
| LLM prompt injection     | PII redaction + schema validation on output                              |
| OAuth token leak         | Server-side only; never exposed to client                                |
| CSRF                     | SameSite cookies + CSRF tokens on form posts                             |

## See also

- `vulnerability-management.md`
- `change-management.md`
- `access-control-policy.md`
