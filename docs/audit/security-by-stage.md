# Security by Stage — JOBBees

**Last reviewed:** 2026-06-09
**Owner:** TODO (Dev)
**Audience:** Client / IT auditor / new contributors

This document maps every security control to the stage of the development lifecycle where it fires. The goal: nothing reaches production without passing through multiple independent gates.

The single one-line summary: **defense in depth across 7 stages, with both automated tools and AI-assistant-level enforcement of project-specific rules.**

---

## The 7 stages

```
1. Developer edit (local)
   ↓
2. AI-assistant gate (security-review skill auto-invoked on sensitive files)
   ↓
3. Pre-commit (lefthook hooks block bad commits)
   ↓
4. Code review / PR (CI runs SAST + tests, reviewer signs off)
   ↓
5. Merge gate (branch protection — all checks green required)
   ↓
6. Deploy (Terraform plan reviewed; manual approval; staging → prod)
   ↓
7. Runtime (WAF + rate limits + observability + audit log)
```

Each stage catches different failure modes. A bug that survives one is likely caught by the next.

---

## Stage 1 — Developer edit (local)

| Control                            | What                                    | How                                                                   |
| ---------------------------------- | --------------------------------------- | --------------------------------------------------------------------- |
| Editor warnings                    | TypeScript strict mode, ESLint live     | `.vscode/settings.json` recommends extensions; `tsconfig.json` strict |
| `.env.local` not in git            | Prevents secret leakage at the source   | `.gitignore` excludes `.env*` (except `.env.example`)                 |
| Local secrets in `.env.local` only | Real keys never typed into source files | Documented in CLAUDE.md                                               |

## Stage 2 — AI-assistant gate (security-review skill)

This is the layer your client is asking about. When Claude Code is editing the codebase, the custom `security-review` skill auto-invokes on changes to sensitive paths and enforces JOBBees-specific rules that no generic tool can know.

| Control                  | What                                                                                                                           | How                                          |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------- |
| **Input validation**     | Every endpoint has a DTO; no `any` body                                                                                        | `.claude/skills/security-review/SKILL.md` §A |
| **AuthN/AuthZ**          | Guards on every non-public route; role + ownership checks                                                                      | §B                                           |
| **Idempotency**          | Every mutating endpoint requires `Idempotency-Key`                                                                             | §C                                           |
| **Rate limits**          | Auth / payment / AI endpoints have explicit limits                                                                             | §D                                           |
| **SQL injection**        | No raw queries with interpolation; soft-delete filter applied                                                                  | §E                                           |
| **PII handling**         | Redaction before LLM calls; no PII in logs; KYC payload minimization                                                           | §F                                           |
| **Secrets**              | No hardcoded keys; Key Vault references in staging/prod                                                                        | §G                                           |
| **Money integrity**      | All amounts in `Int` cents; currency stored; GST via service                                                                   | §H                                           |
| **Webhook signatures**   | Stripe webhook signatures verified before processing (no other webhook providers at MVP — ADR 005 removed identity-vendor KYC) | §H5                                          |
| **Audit trail**          | Money / role / KYC / License changes write to immutable `AuditLog`                                                             | §I                                           |
| **LLM cost + injection** | Cost ceilings; prompt-injection defenses                                                                                       | §J                                           |
| **AU compliance**        | Default `AU` country code; ABN validation; sharing-economy fields                                                              | §K                                           |
| **Test coverage**        | Sensitive routes have 3+ tests including auth-fail                                                                             | §L                                           |

**Triggers automatically on changes to:** `apps/api/src/modules/{auth,payment,payout,tax,kyc,ai,notification}/**`, controllers, webhook handlers, Prisma schema, env files.

Also available: the built-in generic `/security-review` slash command for general-purpose vulnerability scanning. Run both for full coverage.

## Stage 3 — Pre-commit (lefthook)

| Control                  | What                                                     | Tool         |
| ------------------------ | -------------------------------------------------------- | ------------ |
| **Secret scan**          | Blocks commits containing API keys, tokens, private keys | gitleaks     |
| **Lint**                 | ESLint catches unsafe patterns (e.g. `any`, unused vars) | ESLint       |
| **Format**               | Prettier auto-formats; no debate, no style drift         | Prettier     |
| **Type check**           | TypeScript compiles before commit                        | tsc --noEmit |
| **Test (touched files)** | Vitest runs unit tests for changed files                 | Vitest       |

Config: `lefthook.yml` (root)

## Stage 4 — Code review / PR (CI)

| Control                    | What                                                          | Tool                               |
| -------------------------- | ------------------------------------------------------------- | ---------------------------------- |
| **Lint**                   | Repo-wide ESLint                                              | GitHub Actions                     |
| **Test**                   | Full Vitest suite                                             | GitHub Actions                     |
| **Type check**             | Repo-wide tsc                                                 | GitHub Actions                     |
| **Secret scan (CI)**       | Defense in depth vs Stage 3                                   | gitleaks-action                    |
| **SAST (static analysis)** | CodeQL finds vulnerability patterns                           | CodeQL                             |
| **Custom rule scanning**   | Semgrep enforces JOBBees rules (e.g., no `Decimal` for money) | Semgrep (planned Sprint 6)         |
| **Dependency CVE scan**    | Trivy scans npm + container images                            | Trivy (planned Sprint 6)           |
| **Outdated deps**          | Dependabot opens PRs for updates                              | GitHub native                      |
| **Manual review**          | Human reviews payment / tax / PII code line by line           | Required per CLAUDE.md             |
| **PR template checklist**  | Reviewer checks security boxes                                | `.github/pull_request_template.md` |

## Stage 5 — Merge gate (branch protection)

`main` is protected. To merge:

- [ ] All CI checks green
- [ ] At least 1 reviewer approval
- [ ] No open CRITICAL findings from security-review skill
- [ ] HIGH findings have written justification
- [ ] PR description references the work item / ticket

## Stage 6 — Deploy

| Control                    | What                                                                                      | Tool                                |
| -------------------------- | ----------------------------------------------------------------------------------------- | ----------------------------------- |
| **IaC review**             | Terraform plan reviewed before apply                                                      | GitHub Actions + manual approval    |
| **Migration safety**       | Prisma migrations applied only by CI (never by app startup)                               | CI workflow `prisma migrate deploy` |
| **Secrets at deploy time** | Read from Key Vault via App Service Configuration references; never embedded in container | `@Microsoft.KeyVault(...)` syntax   |
| **Staging gate**           | Deploy to staging first; smoke tests; then prod                                           | GitHub Actions workflow             |
| **Manual prod approval**   | Required environment protection rule                                                      | GitHub Environments                 |

## Stage 7 — Runtime

| Control                   | What                                                                       | Where                                  |
| ------------------------- | -------------------------------------------------------------------------- | -------------------------------------- |
| **WAF (OWASP CRS)**       | Block SQLi, XSS, common payloads                                           | Cloudflare Pro at edge                 |
| **DDoS protection**       | L3/L4/L7 mitigation                                                        | Cloudflare anycast                     |
| **Bot blocking**          | Cloudflare Bot Fight Mode                                                  | Cloudflare                             |
| **Geo-restrict admin**    | `admin.jobbees.com.au` AU-only                                             | Cloudflare custom rule                 |
| **Edge rate limits**      | Per-IP at edge for `/auth/*`, `/payment/*`                                 | Cloudflare Rate Limiting               |
| **App-layer rate limits** | Per-user limits in NestJS                                                  | `apps/api/src/common/rate-limit/`      |
| **Network segmentation**  | Postgres / Redis / Blob / Key Vault on private endpoints, no public IPs    | Azure VNet                             |
| **TLS everywhere**        | TLS 1.2+ on edge, mTLS internal where applicable                           | Azure / Cloudflare defaults            |
| **Encryption at rest**    | Azure default (AES-256)                                                    | Azure Storage / Postgres               |
| **Anomaly detection**     | App Insights alerts on error spikes, auth failure spikes, payout anomalies | App Insights                           |
| **Audit log (immutable)** | All money / role / KYC events recorded                                     | `AuditLog` Prisma model                |
| **Incident response**     | Documented playbook                                                        | `docs/audit/incident-response-plan.md` |

---

## Per-category coverage matrix

For each major risk category, here are the stages that have a control:

| Risk                                        | Stages with a control                                                                        |
| ------------------------------------------- | -------------------------------------------------------------------------------------------- |
| **Secret leakage**                          | 1 (`.gitignore`), 3 (gitleaks pre-commit), 4 (gitleaks CI)                                   |
| **SQL injection**                           | 2 (skill §E1), 4 (CodeQL), 7 (WAF)                                                           |
| **XSS / CSRF**                              | 2 (skill §A), 4 (CodeQL), 7 (WAF)                                                            |
| **Broken auth**                             | 2 (skill §B), 4 (manual review), 7 (audit log alerts on auth fail spikes)                    |
| **IDOR / ownership bypass**                 | 2 (skill §B3), 4 (manual review)                                                             |
| **Missing idempotency → duplicate charges** | 2 (skill §C), 4 (manual review of payment), 7 (Stripe-side idempotency too)                  |
| **Rate-limit bypass**                       | 2 (skill §D), 7 (edge rate limits + app rate limits, defense in depth)                       |
| **PII leak via logs**                       | 2 (skill §F2), 4 (review), 7 (log redaction)                                                 |
| **PII leak via LLM**                        | 2 (skill §F1), 4 (review)                                                                    |
| **Money arithmetic bugs**                   | 2 (skill §H), 4 (manual review required for all payment code), 7 (Stripe is source of truth) |
| **Webhook spoofing**                        | 2 (skill §H5), 4 (manual review)                                                             |
| **Tax / RCTI mistakes**                     | 2 (skill §K), 4 (manual review + tax advisor review per CLAUDE.md rule 4)                    |
| **Dependency CVEs**                         | 4 (Trivy + Dependabot)                                                                       |
| **DDoS**                                    | 7 (Cloudflare)                                                                               |
| **Data exfiltration from DB**               | 6 (private endpoints, no public IPs), 7 (audit log + anomaly alerts)                         |

Every category has at least 2 independent stages catching it.

---

## What we do NOT have yet (honest gaps)

| Gap                                       | Plan                                                                    |
| ----------------------------------------- | ----------------------------------------------------------------------- |
| **CodeQL + Semgrep + Trivy active in CI** | Sprint 6 (Compliance & Audit)                                           |
| **Cloudflare WAF stood up**               | Sprint 9 (Launch Hardening, Phase 4)                                    |
| **Private endpoints + VNet**              | Sprint 9 (Launch Hardening, Phase 4)                                    |
| **External pen test**                     | Recommended post-soft-launch, before public launch                      |
| **SOC 2 Type 2 audit (us)**               | Out of scope for MVP; document controls now, audit when scale justifies |
| **Bug bounty program**                    | Out of scope for MVP                                                    |

These are explicitly tracked in the sprint plan, not forgotten.

---

## Comparison to IDE-based auto-scanners (e.g., Google Antigravity)

The client may be asking about tools like **Google Antigravity** that scan every file on edit as part of the IDE. Here's the honest comparison:

| Aspect                                      | IDE auto-scanner (e.g., Antigravity)          | JOBBees `security-review` skill                                     |
| ------------------------------------------- | --------------------------------------------- | ------------------------------------------------------------------- |
| Runs on                                     | Every file save in the IDE                    | Every Claude-Code edit to sensitive paths + on-demand               |
| Coverage                                    | Generic vulnerability patterns (CWE-style)    | Project-specific rules (idempotency, money-in-cents, AU compliance) |
| Knows the project                           | No (looks at single files)                    | Yes (reads CLAUDE.md, ADRs, audit docs)                             |
| Catches IDOR (ownership bugs)               | Sometimes — depends on tool                   | Yes (skill check B3)                                                |
| Catches "money stored as Float"             | Maybe (if it has a custom rule)               | Yes (skill check H1)                                                |
| Catches "PII sent to LLM without redaction" | No (would not understand the redaction layer) | Yes (skill check F1)                                                |
| Catches "missing Idempotency-Key"           | No                                            | Yes (skill check C1)                                                |
| Catches generic SQL injection               | Yes                                           | Yes (and CodeQL also)                                               |
| Catches dependency CVEs                     | Yes (if integrated)                           | No — that's Trivy's job                                             |

**Conclusion:** the skill is **complementary** to IDE auto-scanners, not a replacement. IDE scanners catch generic patterns. The skill catches project-specific failure modes that generic tools cannot know about.

For full coverage we run:

- IDE-level lint / type-check / live error highlighting (Stage 1)
- `security-review` skill on AI edits (Stage 2)
- gitleaks pre-commit (Stage 3)
- CodeQL + Semgrep + Trivy in CI (Stage 4, planned)
- Manual review on payment / tax / PII (Stage 4, always)
- WAF + edge controls at runtime (Stage 7)

---

## What "complete security" means for JOBBees

There is no such thing as 100% complete security in any system. What we can credibly say is:

1. **Every major vulnerability category has at least two independent controls.**
2. **AI-authored code passes through a project-specific gate before commit.**
3. **Money, tax, and PII code requires human review on top of automated controls** (CLAUDE.md rule 2).
4. **Runtime defenses (WAF, rate limits, audit log, anomaly alerts) catch what slips through.**
5. **Incidents have a documented response plan** (`docs/audit/incident-response-plan.md`).
6. **Compliance posture is mapped to recognized frameworks** (ISO 27001, SOC 2 controls documented in `docs/audit/`).

This is the standard responsible engineering posture for an AU payment-handling marketplace.

---

## References

- `.claude/skills/security-review/SKILL.md` — the skill itself
- `CLAUDE.md` — root rules and non-negotiables
- `PROJECT_CONTEXT.md` — full architecture
- `docs/audit/edge-security.md` — WAF + DDoS + network segmentation
- `docs/audit/incident-response-plan.md` — what to do during an incident
- `docs/audit/vulnerability-management.md` — runtime + scanning controls
- `docs/audit/encryption-policy.md` — TLS + at-rest encryption
- `docs/audit/access-control-policy.md` — RBAC + admin access
- `docs/audit/data-retention.md` — 7-year financial retention + DSR
