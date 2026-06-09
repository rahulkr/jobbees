# JOBBees security tooling

This directory holds project-specific security configuration that runs in CI and locally.

## Files

| File                | Purpose                                                                            |
| ------------------- | ---------------------------------------------------------------------------------- |
| `semgrep-rules.yml` | JOBBees-specific Semgrep rules (~20 rules) — enforces conventions from `CLAUDE.md` |

### What's enforced by Semgrep vs by the skill / PR template

Semgrep is great at **syntactic patterns that can be expressed as a complete fragment of code** (a raw query, a hardcoded key, a schema column type). It struggles with **"this method has decorator X anywhere on it" or "this body contains call Y somewhere"** because those require structural reasoning Semgrep's TS parser doesn't fully support.

So we split:

| Check type                                            | Enforced by                                                                               |
| ----------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Money type in Prisma (`Decimal` / `Float`)            | **Semgrep** — schema patterns are exact                                                   |
| Hardcoded API keys, raw queries, audit-log mutation   | **Semgrep**                                                                               |
| cuid1 / autoincrement IDs, currency-field-presence    | **Semgrep**                                                                               |
| Inline GST math, soft-delete filter, LLM redaction    | **Semgrep**                                                                               |
| `@UseGuards(JwtAuthGuard)` on every controller method | **Skill + PR template + human review** (decorator-presence checks are brittle in Semgrep) |
| `@UseInterceptors(IdempotencyInterceptor)` presence   | **Skill + PR template**                                                                   |
| `@RateLimit(...)` on auth endpoints                   | **Skill + PR template**                                                                   |
| Webhook body contains `constructEvent(...)`           | **Skill + PR template**                                                                   |

## Running Semgrep locally

```bash
# Install once (Homebrew on macOS)
brew install semgrep

# Run just the JOBBees rules
semgrep --config ops/security/semgrep-rules.yml apps packages

# Run JOBBees rules + Semgrep registry baseline (recommended)
semgrep \
  --config p/typescript \
  --config p/nestjs \
  --config p/owasp-top-ten \
  --config ops/security/semgrep-rules.yml \
  apps packages

# Show only ERROR severity (for a quick triage view)
semgrep --config ops/security/semgrep-rules.yml --severity ERROR apps packages

# Output as JSON (for further processing)
semgrep --config ops/security/semgrep-rules.yml --json apps packages
```

## How it relates to the other layers

| Layer                              | What it catches                                                        | Where                                     |
| ---------------------------------- | ---------------------------------------------------------------------- | ----------------------------------------- |
| **`security-review` Claude skill** | JOBBees rules, AT AI EDIT TIME                                         | `.claude/skills/security-review/SKILL.md` |
| **Semgrep (this directory)**       | JOBBees rules, on every PR + local — works even when no AI is involved | `ops/security/semgrep-rules.yml`          |
| **CodeQL**                         | Generic SAST (planned Sprint 6)                                        | `.github/workflows/codeql.yml`            |
| **Trivy**                          | Dependency CVEs + container scans (planned Sprint 6)                   | `.github/workflows/trivy.yml`             |
| **gitleaks**                       | Hardcoded secrets, pre-commit + CI                                     | `lefthook.yml`                            |
| **Cloudflare WAF**                 | Runtime — OWASP attacks (Sprint 9)                                     | `docs/audit/edge-security.md`             |

The Semgrep file here is the **non-AI mirror** of the skill — anyone editing code (with or without Claude) gets the same checks on their PR.

## Tuning false positives

If a rule produces a false positive:

1. Confirm it's truly a false positive (the rule fires but the code is genuinely safe)
2. Add the file pattern to the rule's `paths.exclude` list, OR
3. Add a `// nosemgrep: rule-id` comment on the specific line (must include the rule id; bare `// nosemgrep` is too broad)
4. Open a PR documenting WHY the suppression is acceptable

Do NOT silently delete or weaken rules. If a rule is genuinely wrong (not just inconvenient), discuss in a PR.

## Adding new rules

When you add a new convention to `CLAUDE.md`, add a mirror rule here. Each rule should:

- Have a `jobbees-` prefixed id
- Point to the corresponding `.claude/skills/security-review/SKILL.md` check
- Set severity to ERROR only if violation is a CLAUDE.md hard rule (otherwise WARNING)
- Include `paths.exclude` for tests and fixtures where appropriate

## References

- `.claude/skills/security-review/SKILL.md` — the AI-side mirror of these rules
- `docs/audit/security-by-stage.md` — how all layers fit together
- `CLAUDE.md` — the source of truth for project conventions
