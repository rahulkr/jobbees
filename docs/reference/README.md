# Reference documents

External documents that the sprint plan was reconciled against. Not edited locally — these are snapshots of the source-of-truth held elsewhere.

## Files

### `estimation-v1.2.csv`

Saiju's Feature Estimation v1.2 (Jun 2026). 474 features across 8 components (1 Mobile, 2 Backend, 3 Admin, 4 Flutter Web, 5 Next.js SEO, 6 AI Infra, 7 DevOps, 8 FSE Module). 398 in-scope; ~1,420 raw hours.

Every IN, IN★, and THIN row from this estimate has a sprint home in `docs/sprints/`. The cross-reference table at the bottom of `docs/sprints/post-mvp-deferred.md` lists every estimate ID and where it lives.

**Source of truth lives in Saiju's Google Drive.** This CSV is a snapshot from 14 Jun 2026 used for the row-by-row coverage audit. If you need the latest, ask Saiju.

## When to refer here

- Cross-checking a sprint row against the estimate (does the ID exist? what's the original hours estimate? what's the Architect Note?)
- Auditing scope at end-of-sprint coverage gate
- Onboarding a new contributor — read the estimate to understand the marketplace's full surface area

## When NOT to edit

Never edit `estimation-v1.2.csv` directly. It's a snapshot. If Saiju ships v1.3 we replace the file wholesale.
