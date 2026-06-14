# Sprints

This directory holds the 13-sprint MVP plan (Sprint 0 setup + 12 build sprints).

## Read in this order

1. **`PLAN.md`** — master plan: dates, themes, hours, demo cadence, tracking, principles, open decisions, risks
2. **Current sprint doc** — pick the one matching today's date

## Files

| File                                       | Sprint | Dates                   | Theme                                                                                        |
| ------------------------------------------ | ------ | ----------------------- | -------------------------------------------------------------------------------------------- |
| `PLAN.md`                                  | n/a    | Jun 1 – Dec 4 2026      | Master plan                                                                                  |
| `sprint-00-foundation-and-setup.md`        | 0      | Mon 1 Jun → Fri 19 Jun  | Foundation + AI setup + security tooling (extended 1 week for research catch-up)             |
| `sprint-01-onboarding-and-auth.md`         | 1      | Mon 22 Jun → Fri 3 Jul  | **Backend Auth Foundation** (backend-only — no mobile this sprint)                           |
| `sprint-02-kyc-tasker-connect.md`          | 2      | Mon 6 Jul → Fri 17 Jul  | Mobile Auth + Onboarding + Tasker upgrade + Stripe Connect + ABN (first user-visible sprint) |
| `sprint-03-task-posting-ai.md`             | 3      | Mon 20 Jul → Fri 31 Jul | Job posting + AI extraction + guest mode                                                     |
| `sprint-04-discovery-bidding.md`           | 4      | Mon 3 Aug → Fri 14 Aug  | Discovery + Offering + Q&A + **License verification + offer-time guard** (per ADR 005)       |
| `sprint-05-messaging-payments.md`          | 5      | Mon 17 Aug → Fri 28 Aug | Messaging + Payments core + OTP swap                                                         |
| `sprint-06-execution-tax.md`               | 6      | Mon 31 Aug → Fri 11 Sep | Job execution + Tax/RCTI/ATO                                                                 |
| `sprint-07-reviews-disputes.md`            | 7      | Mon 14 Sep → Fri 25 Sep | Reviews + Disputes (Tier-0 mediator)                                                         |
| `sprint-08-notifications-trust-privacy.md` | 8      | Mon 28 Sep → Fri 9 Oct  | Notifications + Trust/Safety + Privacy                                                       |
| `sprint-09-admin-console.md`               | 9      | Mon 12 Oct → Fri 23 Oct | Admin console end-to-end (incl. full License Review Queue UI)                                |
| `sprint-10-devops-cloud.md`                | 10     | Mon 26 Oct → Fri 6 Nov  | DevOps + Cloud + WAF                                                                         |
| `sprint-11-testflight-bugfix.md`           | 11     | Mon 9 Nov → Fri 20 Nov  | TestFlight + Bug-fix + Launch hardening                                                      |
| `sprint-12-soft-launch.md`                 | 12     | Mon 23 Nov → Fri 4 Dec  | Soft launch + Retrospective                                                                  |

## How each sprint doc is structured

Every sprint detail file has the same sections, in the same order:

1. **Dates + theme + hours budget**
2. **Goal in one sentence** — the friday-demo bar
3. **Scope** — inventory rows in scope, broken out by surface (Mobile / Backend / Admin)
4. **Schema additions** — new Prisma models needed
5. **Decision gates** — what must be decided before the sprint can start
6. **Definition of done** — per-feature DoD with skill / PR template references
7. **Friday demo script** — minute-by-minute client demo
8. **Risks** — likelihood × impact × mitigation
9. **Explicitly NOT in scope** — to prevent scope creep
10. **Day-by-day rough plan** — mobile + backend, per working day
11. **Definition of "shippable"** — sprint completion gate
12. **Expected PRs** — suggested PR slicing (target < 400 LOC each)

## What an AI session should do at the start of each coding day

1. Read `PLAN.md` (or just glance at the table) → identify current sprint
2. Read that sprint's detail doc → understand today's day-by-day item
3. Pick a feature row (an inventory ID listed in the sprint scope)
4. Open a feature branch: `feat/<short-name>`
5. Code, write tests, run `./scripts/coverage.sh` to verify progress
6. PR using `.github/pull_request_template.md` — close inventory row in description

## Updates

The sprint plan is meant to be a living doc. It's expected to change:

- **End of each sprint** — update CSV (column 9: `done [sprint-N, PR#nn]`), draft next sprint's detail doc if not already
- **Mid-sprint scope changes** — record in the sprint doc's "Notes" section + the Friday demo's stoplight
- **Major decisions** — record in `docs/adrs/`, link from the sprint doc

The 12 sprint themes themselves should not change without a re-plan. The day-by-day work plan can be tuned each sprint.

## Related docs

- `inventory/JOBBees_Feature_Inventory.csv` (gitignored) — the 522-row source of truth referenced by inventory ID throughout
- `scripts/coverage.sh` — weekly coverage report
- `docs/adrs/` — architecture decisions (some referenced by sprint docs)
- `docs/audit/` — IT audit docs (some referenced by Friday demo scripts)
- `.github/pull_request_template.md` — the PR template each sprint's PRs should use
- `.claude/skills/security-review/SKILL.md` — security gate that auto-invokes on sensitive paths

## Post-MVP

After Sprint 12 ships:

- `PLAN.md` → renamed to `PLAN-mvp-v1.md` for historical reference
- New `PLAN.md` drafted for post-MVP work (scaling, additional suburbs, deferred POST features)
- `retrospective.md` lessons captured
- `post-mvp-deferred.md` lists any IN/IN★ rows that didn't ship with justification
