# Architecture Decision Records

Numbered, immutable records of significant architectural decisions.

## Index

- [001 — Monorepo and Stack Choices](./001-monorepo-and-stack.md)
- [002 — Database Conventions](./002-database-conventions.md)
- [003 — Multi-Country Readiness](./003-multi-country-readiness.md)
- [004 — Category Types (Transactional vs Lead)](./004-category-types.md)

## Conventions

- One file per decision, numbered `NNN-kebab-case-title.md`
- Status: **Proposed** → **Accepted** → **Superseded** (with a link to the superseding ADR)
- Never edit an Accepted ADR — write a new one that supersedes it
- Each ADR has: Context, Decision, Consequences, Alternatives Considered, References

## When to write an ADR

- Choosing between alternatives that meaningfully affect the system (framework, database, hosting, key library)
- Locking a convention you don't want anyone (including future-you, including AI) to silently override
- Reversing a previous decision (write a new ADR that supersedes the old)

## When NOT to write an ADR

- Minor library upgrades
- Bugfix decisions
- Day-to-day implementation choices (those go in code comments or CLAUDE.md)
