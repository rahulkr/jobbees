# Post-MVP Deferred Items

> **Status:** Living document.
> **Owner:** Saiju (founder / product) + Rahul (lead dev).
> **Created:** 2026-06-14 — in response to the JOBBees Scope Reconciliation review.
> **Purpose:** A single source of truth for everything in Estimation v1.2 that is **consciously not built in MVP**. Every item below has been triaged: keep, build now, defer (this file), or drop. Items here are deferred — they will be revisited after soft launch and may move into a V2 / V1.x roadmap.

This appendix is referenced by [`PLAN.md`](./PLAN.md) and was promised by it in three places (lines 249, 288, 326). It closes the loop with the Sprint Detail Booklet so all three artifacts (estimate, sprint plan, this appendix) agree.

---

## Decision values

| Value                        | Meaning                                                                                                                                             |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| **DEFERRED — V2**            | Agreed post-MVP. Will revisit after soft launch. Documented here.                                                                                   |
| **DEFERRED — risk-accepted** | Same as above, but explicitly accepted as a risk during MVP (e.g., behavioural fraud at one-suburb scale). Founder sign-off required before launch. |
| **DROPPED**                  | Cut permanently. No revisit planned.                                                                                                                |
| **COVERED — locked**         | Already in scope under a different name / approach. ADR or sprint doc cited.                                                                        |
| **WILL-ADD — sprint N**      | Reinstated. Added to a named sprint. **Not in this file** — see the relevant sprint doc.                                                            |

---

## Deferred items (V2 candidates)

### 1. LLM message moderation upgrade (B-23 — regex → LLM upgrade path)

- **Decision:** DEFERRED — V2 — upgrade path
- **MVP approach:** Regex off-platform contact detection (Sprint 5) PLUS a coded-variant + unicode evasion corpus added to the regex test suite (per reconciliation #13). Documented limitation: regex misses creative encodings ("zero four one two", emoji-substituted digits, "the gram").
- **Why deferred at MVP:** Regex is cheap to ship, deterministic, easy to test. LLM moderation has per-message cost and false-positive risk.
- **Revisit trigger:** Flagged regex bypass observed in production, OR >100 messages/day where coverage matters.

### 2. Full SLA alerting + log PII redaction tooling (gap in section 7.2)

- **Decision:** PARTIAL — App Insights + manual SLA review at MVP
- **MVP approach:** App Insights (Sprint 10) captures the metrics; founder reviews weekly. PII redaction in logs is enforced at write time via `pino.redact` (per `security-review` skill §F2), not via downstream tooling.
- **Why deferred:** Full SLA alerting / SLO dashboards / log scrubbing tooling are operational maturity items, not launch blockers.
- **Revisit trigger:** First SLA-affecting incident.

---

## Items Saiju's review flagged — but actually already in scope

These appear in the reconciliation review but are committed in our repo. Listed here for completeness so they don't show up in a future review as "missing."

| Item                                                                                        | Where committed                                                                                                                                                                                                                                                                                   | Notes                                                                                                                                                                                |
| ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| KYC via Stripe Connect (AP-04)                                                              | [ADR 005](../adrs/005-kyc-strategy.md)                                                                                                                                                                                                                                                            | Manual ID queue eliminated. Stripe Connect verification states are the sole identity trust gate.                                                                                     |
| Pen test (post-launch, within 60 days)                                                      | [PROJECT_CONTEXT.md §11](../../PROJECT_CONTEXT.md), [PLAN.md line 293](./PLAN.md), [audit/vulnerability-management.md](../audit/vulnerability-management.md), [audit/security-by-stage.md](../audit/security-by-stage.md), [audit/secure-sdlc.md](../audit/secure-sdlc.md), Sprint Detail Booklet | Plus the reconciliation prompted a **scoped pre-launch test of payment + auth + PII** added to Sprint 11 (see [`sprint-11-testflight-bugfix.md`](./sprint-11-testflight-bugfix.md)). |
| Single admin role at MVP                                                                    | Locked decision, schema (`UserRole.ADMIN` + `SUPER_ADMIN`)                                                                                                                                                                                                                                        | Two-person approval moves with this (item #6 above).                                                                                                                                 |
| Per-class data retention (financial 7y, jobs 2y, threads 2y, AuditLog 7y, ConsentRecord 7y) | [audit/data-retention-policy.md](../audit/data-retention-policy.md)                                                                                                                                                                                                                               | Saiju's review said "threads 7y" — confirm with him; our policy says 2y. Enforcement crons added to Sprint 8 (separate gap, now closed).                                             |
| 4 user roles (CLIENT, TASKER, ADMIN, SUPER_ADMIN)                                           | Schema, [sprint-01](./sprint-01-onboarding-and-auth.md)                                                                                                                                                                                                                                           | Matches Saiju's "4 roles only" coverage map note.                                                                                                                                    |
| Cloudflare Pro WAF vs Azure Front Door                                                      | [ADR 007](../adrs/007-edge-security.md)                                                                                                                                                                                                                                                           | Saiju's CHANGED ITEMS row confirms WAF / DDoS / bot coverage is intact.                                                                                                              |
| Local FS → Azure Blob migration at S10                                                      | [PLAN.md](./PLAN.md), Sprint 10                                                                                                                                                                                                                                                                   | Migration-integrity test added to Sprint 10 per reconciliation. Documented "no sensitive data on local disk interim" rule.                                                           |

---

## Items Saiju's review flagged that we WILL ADD (not deferred)

These were also surfaced by the reconciliation but are not in this appendix because they are now in a sprint. Listed for cross-reference only:

| Item                                                                                                     | Now in sprint                      | Section                                                                                                                                          |
| -------------------------------------------------------------------------------------------------------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| LLM observability (AI-02, Langfuse)                                                                      | Sprint 3                           | AI infrastructure cluster                                                                                                                        |
| Prompt versioning + eval harness (AI-03)                                                                 | Sprint 3                           | AI infrastructure cluster                                                                                                                        |
| AI cost quotas (AI-12, NFR-C01)                                                                          | Sprint 3                           | AI infrastructure cluster                                                                                                                        |
| AI output validators (AI-04, Zod cross-cutting)                                                          | Sprint 3                           | AI infrastructure cluster                                                                                                                        |
| Prompt-injection defense helper (B-51)                                                                   | Sprint 3                           | AI infrastructure cluster                                                                                                                        |
| Product analytics (217, PostHog)                                                                         | Sprint 2                           | Cross-cutting (instrument as we build)                                                                                                           |
| Sentry client crash SDK (216)                                                                            | Sprint 2                           | Cross-cutting                                                                                                                                    |
| Deep linking — Universal/App Links (206)                                                                 | Sprint 2                           | Cross-cutting                                                                                                                                    |
| Mobile a11y foundations (218)                                                                            | Sprint 2                           | Cross-cutting + Sprint 11 audit                                                                                                                  |
| DB-level AuditLog immutability (AP-46/52 audit)                                                          | Sprint 1                           | Auth foundation                                                                                                                                  |
| Webhook DLQ (B-19/AP-44)                                                                                 | Sprint 5                           | BullMQ DLQ for failed webhook handlers                                                                                                           |
| Webhook admin replay viewer (AP-44)                                                                      | Sprint 9                           | Admin console                                                                                                                                    |
| bull-board admin queue monitor (AP-45)                                                                   | Sprint 9                           | Admin console                                                                                                                                    |
| Weekly + monthly report crons (AP-51)                                                                    | Sprint 9                           | Admin console                                                                                                                                    |
| Per-class retention crons (B-58)                                                                         | Sprint 8                           | Notifications + retention                                                                                                                        |
| Maintenance mode + offline indicator (210/211)                                                           | Sprint 11                          | TestFlight polish                                                                                                                                |
| Mobile a11y audit (218)                                                                                  | Sprint 11                          | TestFlight polish                                                                                                                                |
| Scoped pre-launch pen test (payment + auth + PII)                                                        | Sprint 11                          | Pre-launch verification                                                                                                                          |
| Regex moderation evasion corpus (B-53/B-23)                                                              | Sprint 5                           | Messaging                                                                                                                                        |
| **Flutter Web app (FW-01..18, full parity)** — _re-scoped IN per founder direction 14 Jun 2026_          | Sprints 1, 2, 3, 4, 5, 6, 7, 8, 11 | Web target enablement + Web parity row per user-visible sprint + final responsive polish                                                         |
| **Next.js SEO public site (SEO-01..19, full bundle)** — _re-scoped IN per founder direction 14 Jun 2026_ | Sprints 3 + 11                     | Public job pages indexable in S3, full SEO bundle in S11                                                                                         |
| **AI auto-SEO content generation (AI-07)** — _re-scoped IN per founder direction 14 Jun 2026_            | Sprint 11                          | Paired with the SEO bundle                                                                                                                       |
| **Behavioural fraud scoring (B-48)** — _re-scoped IN per Estimation v1.2 verification 14 Jun_            | Sprint 7                           | IN★ per estimate. Velocity / collusion / platform-leakage signals; admin queue triage.                                                           |
| **Device fingerprinting (M-229)** — _re-scoped IN per Estimation v1.2 verification 14 Jun_               | Sprint 8                           | FingerprintJS Pro at signup. Feeds fraud graph + multi-account detection (paired with B-48).                                                     |
| **Two-person approval rule (AP-56)** — _re-scoped IN per Estimation v1.2 verification 14 Jun_            | Sprint 9                           | Sub Admin initiates → Super Admin approves. Covers refunds >$1k, hard delete, bulk ops >50 records. Maker-checker enforced via SUPER_ADMIN role. |
| **RAG support agent (#194)** — _re-scoped IN per Estimation v1.2 verification 14 Jun_                    | Sprint 8                           | In-app chat using Claude Haiku + pgvector over FAQ corpus. Targets 60-80% L1 deflection.                                                         |
| **Ad-hoc Report Builder NL queries (AP-52)** — _re-scoped IN per Estimation v1.2 verification 14 Jun_    | Sprint 9                           | IN★ per estimate. Blueprint §31. Uses AI-01 LLM router (Sprint 3) for NL→SQL.                                                                    |
| **24-tile Super User Dashboard (AP-53)** — _re-scoped IN per Estimation v1.2 verification 14 Jun_        | Sprint 9                           | IN per estimate. Blueprint §32. 24 tiles × 6 sections, REST polling, replaces the simpler KPI panel.                                             |
| **Feature store THIN (AI-05)** — _re-scoped IN per Estimation v1.2 verification 14 Jun_                  | Sprint 4                           | THIN per estimate. Postgres-backed feature table read by the composite ranker. Nightly refresh. LightGBM ranker remains POST.                    |
| **Moderation pipeline orchestrator (B-53)** — _re-scoped IN per Estimation v1.2 verification 14 Jun_     | Sprint 5                           | IN per estimate. BullMQ fan-out for moderation: new task / message / photo / review → relevant checks.                                           |

---

## How this file gets updated

1. Anything we decide to drop or defer mid-sprint goes here, with: who decided, when, why, revisit trigger.
2. Anything we decide to pull back into MVP gets removed from this file and added to a sprint doc, with a one-line note in the sprint's "Why this is here" section.
3. At end of MVP (Sprint 12 wrap), the items in this file become the V2 backlog seed.
4. This file is referenced by [`PLAN.md`](./PLAN.md) and the Sprint Detail Booklet — keep them in sync.

## How a future scope reconciliation should treat this file

A future reviewer comparing Estimation v1.x against the sprint plan should find every estimate row either:

1. In a sprint doc (status = built or scheduled), OR
2. In this file (status = deferred / risk-accepted), OR
3. Explicitly removed from estimate v1.x with a written note.

No estimate row should silently disappear into a coverage gap. The scope-coverage gate in PLAN.md exists to enforce this every Friday demo.
