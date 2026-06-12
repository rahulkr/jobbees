# Sprint 7 — Reviews + Disputes (Tier-0 LLM mediator)

**Dates:** Mon 14 Sep → Fri 25 Sep 2026 (10 working days)
**Theme:** Both sides leave reviews (blind, timeout-reveal), and when something goes wrong the AI mediator proposes a resolution that humans can accept, reject, or escalate.
**Hours budget:** ~95 (40 mobile, 55 backend)
**Mid-sprint demo:** Fri 18 Sep
**End-of-sprint demo:** Fri 25 Sep

## Goal in one sentence

By Friday 18 Sep, after a completed job both parties leave reviews (only revealed when both submit or 14d passes), and if a dispute is raised, the Tier-0 LLM mediator analyses the thread + evidence + completion proof and proposes one of three resolutions which either party can accept, reject, or escalate to an admin who sees a co-pilot brief.

## Scope — inventory rows

### Mobile (apps/mobile)

| ID  | Item                                          | Call | Hrs | Notes                        |
| --- | --------------------------------------------- | ---- | --- | ---------------------------- |
| 150 | Post-completion review prompt (both sides)    | IN   | 2   |                              |
| 151 | Star rating                                   | IN   | 1   |                              |
| 152 | Text review with min length                   | IN   | 1   |                              |
| 153 | Blind review with timeout-reveal              | IN   | 2   |                              |
| 155 | Response to review (one-time, public)         | THIN | 2   |                              |
| 157 | Report review                                 | IN   | 1   |                              |
| 158 | Dispute initiation flow                       | IN   | 3   |                              |
| 159 | Reason picker                                 | IN   | 1   |                              |
| 160 | Evidence upload (photos, message screenshots) | IN   | 3   |                              |
| 161 | Dispute conversation thread                   | IN   | 3   |                              |
| 162 | AI-proposed resolution screen                 | IN★  | 3   | Render proposal from backend |
| 163 | Accept proposal                               | IN★  | 1   |                              |
| 164 | Reject / escalate to human admin              | IN★  | 1   |                              |
| 165 | Dispute status tracker                        | IN   | 2   |                              |
| 166 | Resolution outcome screen                     | IN   | 2   |                              |

**Mobile total: ~28h**

### Backend (apps/api)

| ID  | Item                                                 | Call | Hrs | Notes                                                   |
| --- | ---------------------------------------------------- | ---- | --- | ------------------------------------------------------- |
| 323 | Review CRUD                                          | IN   | 4   |                                                         |
| 324 | Blind review with timeout-reveal                     | IN   | 3   |                                                         |
| 325 | Response-to-review API                               | THIN | 2   |                                                         |
| 328 | Review removal API (admin-triggered)                 | IN   | 2   |                                                         |
| 329 | Minimum-length enforcement                           | IN   | 1   |                                                         |
| 330 | Dispute CRUD                                         | IN   | 4   |                                                         |
| 331 | Dispute state machine                                | IN   | 3   | OPEN/TIER0_PROPOSED/ACCEPTED/ESCALATED/RESOLVED/CLOSED  |
| 332 | Tier-0 LLM mediator agent                            | IN★  | 14  | Prompt eng, evidence agg, schema validation, cost guard |
| 333 | Evidence collection API                              | IN   | 3   |                                                         |
| 334 | Resolution proposal generation (full/partial/refund) | IN★  | 4   |                                                         |
| 335 | Tier-0 threshold config (≤ AUD $200)                 | IN★  | 1   |                                                         |
| 336 | Accept / reject proposal logic                       | IN★  | 2   |                                                         |
| 337 | Escalation to human admin                            | IN★  | 2   |                                                         |
| 338 | Admin case brief generation (co-pilot)               | IN★  | 8   | Separate prompt, structured output                      |

**Backend total: ~53h**

### Schema additions

- Review: already in schema. Confirm `visibleAt DateTime?` (blind review timeout-reveal) and `response String?`, `responseAt DateTime?` already present
- New `Dispute` model (from FUTURE MODELS): `id`, `taskId`, `paymentId`, `initiatorId`, `initiatorRole ENUM(POSTER, TASKER)`, `reason`, `state DisputeState`, `tier0ProposalId String?`, `tier0ResolvedAt DateTime?`, `escalatedAt DateTime?`, `escalatedToAdminId String?`, `resolvedAt DateTime?`, `resolutionType ENUM(FULL_RELEASE, PARTIAL_RELEASE, REFUND, NO_ACTION)`, `resolutionAmountCents Int?`, `createdAt`, `updatedAt`
- New `DisputeEvidence` model: `id`, `disputeId`, `submitterId`, `type ENUM(PHOTO, MESSAGE_SCREENSHOT, COMPLETION_PROOF, TEXT)`, `blobUrl String?`, `textContent String?`, `submittedAt`
- New `Tier0Proposal` model: `id`, `disputeId`, `modelUsed`, `proposalType ENUM(FULL_RELEASE, PARTIAL_RELEASE, REFUND)`, `proposalAmountCents Int`, `rationale Text`, `confidenceScore Float`, `tokensUsed Int`, `costUsd Float`, `createdAt`, `acceptedAt DateTime?`, `rejectedAt DateTime?`, `rejectedBy String?`
- New `AdminCaseBrief` model: `id`, `disputeId`, `summary Text`, `keyMessages Json`, `evidenceSummary Text`, `precedentRefs Json?`, `recommendation Text`, `modelUsed`, `tokensUsed Int`, `costUsd Float`, `createdAt`
- Add `Report` model for reported reviews (already added in S5 for messages — extend `targetType` enum to include `REVIEW`)

## Definition of done

Same as Sprint 1, plus per `.claude/skills/tier0-dispute/SKILL.md`:

- [ ] Tier-0 only triggers on disputes with payment ≤ AUD $200 (skill threshold check)
- [ ] Tier-0 output is schema-validated (Zod) — if validation fails, escalate to human
- [ ] Tier-0 cost per dispute < $0.10 average (cost guard enforced)
- [ ] PII redacted from messages/evidence before passing to Tier-0 prompt (skill §F1)
- [ ] AuditLog write on every dispute state transition + every Tier-0 proposal acceptance
- [ ] Blind review reveal: both parties submitted OR 14 days passed (whichever first)
- [ ] Acceptance test: seed 10 sample disputes (varied scenarios), Tier-0 produces sensible proposal for ≥7/10 (manual eval)

## Friday demo script (end-of-sprint Fri 18 Sep)

5-6 min:

```
00:00 — "Sprint 7 wrap. Reviews + the AI mediator. Real dispute scenario."
00:15 — Device A (poster): completed task screen → "Leave a review"
        prompt fires. Tap.
00:30 — Star rating: 4 stars. Text review: "Job was good but tasker
        left some sawdust behind." Submit. Show min-length enforcement.
00:50 — Device B (tasker): "Leave a review" prompt for the same task.
        4 stars. Text: "Easy job, poster was helpful." Submit.
01:05 — Both reviews now visible (blind reveal triggered — both submitted).
        Show on profile.
01:20 — Demo single-side scenario: only one party reviews, fast-forward
        14d, show timeout-reveal.
01:40 — Now the dispute scenario: a different (seeded) job where poster
        is unhappy. Device A: tap "Open dispute" on completed job.
01:55 — Reason picker: "Work not completed to standard".
        Evidence upload: 2 photos + screenshot of last 3 chat messages.
        Submit.
02:15 — Backend: Tier-0 mediator processes (loading spinner with
        "Analysing dispute..." text). Cost guard fires (under $0.10).
02:35 — Mobile receives proposal: "I've reviewed the thread, the
        completion proof, and the evidence. I propose a partial release
        of 65% to the tasker ($130 of $200) because the work was 80%
        complete but the cleanup wasn't done. Tasker has the option to
        return and complete the cleanup at no charge in lieu of the
        $70 refund."
02:55 — Device A: show option Accept / Reject. Tap Reject ("I want a
        full refund").
03:10 — Device B (tasker): receives "Dispute proposal rejected. Returning
        to admin for human review."
03:25 — Switch to admin: dispute queue. Open the dispute → see admin
        case brief co-pilot output: timeline of events, key messages,
        evidence summary, precedent refs, recommendation. Show how it
        accelerates admin decision.
03:50 — Admin resolves manually: "Partial release 70% ($140) to tasker,
        $60 refund to poster". Show the resolution outcome screen
        propagate to both parties.
04:10 — Show Tier-0 telemetry: cost per dispute, accuracy on hand-
        graded sample.
04:25 — Coverage report. Stoplight + asks. End.
```

## Risks

| Risk                                                                 | Likelihood | Impact   | Mitigation                                                                  |
| -------------------------------------------------------------------- | ---------- | -------- | --------------------------------------------------------------------------- |
| Tier-0 proposes biased outcomes (favours one side systematically)    | Medium     | High     | Manual eval on 10 sample disputes before merging; if biased, iterate prompt |
| Tier-0 cost spikes (long thread + many evidence pieces)              | Medium     | Medium   | Cost guard at $0.50/dispute hard limit, alert at $0.10 average              |
| PII leaks into Tier-0 prompt (skipped redaction)                     | Low        | Critical | Automated test: prompt input must pass through `redactPii()`                |
| Blind review timeout-reveal cron timing edge case                    | Low        | Low      | Test with mocked dates; document in code                                    |
| Disputes < $200 threshold is wrong cutoff                            | Medium     | Low      | Admin config (S9) to tune threshold; start at $200                          |
| Review removal admin tool used to delete legitimate negative reviews | Low        | Medium   | Audit log every removal; tracked in admin audit log viewer (S9)             |
| Evidence upload exceeds size limits                                  | Medium     | Low      | Size cap at 10MB per file, 50MB per dispute                                 |

## Explicitly NOT in scope

- Review authenticity scoring — POST (inventory row 326)
- Collusion detection (repeat pairs) — POST (inventory row 327)
- Precedent retrieval (similarity over past disputes) — THIN, S8 buffer if time
- Edit / delete own review (within window) — THIN (inventory row 156) — defer to S8
- Photo attachment in review — THIN (inventory row 154) — defer to S8

## Day-by-day rough plan

| Day          | Mobile                                                | Backend                                                     |
| ------------ | ----------------------------------------------------- | ----------------------------------------------------------- |
| Mon 7 (D1)   | Review prompt + star rating + text input.             | Review CRUD + min-length. Dispute models.                   |
| Tue 8 (D2)   | Blind review with timeout-reveal UI.                  | Blind review reveal logic + cron.                           |
| Wed 9 (D3)   | Response-to-review + report review.                   | Response API + admin review removal. Dispute state machine. |
| Thu 10 (D4)  | Dispute initiation + reason picker + evidence upload. | Tier-0 mediator prompt v1. Evidence collection.             |
| Fri 11 (D5)  | Mid-sprint demo + catch-up.                           | Tier-0 schema validation + cost guard.                      |
| Mon 14 (D6)  | AI proposal screen + accept/reject.                   | Tier-0 resolution proposal generation + threshold.          |
| Tue 15 (D7)  | Dispute conversation thread + status tracker.         | Accept/reject logic. Escalation flow.                       |
| Wed 16 (D8)  | Resolution outcome screen. Polish.                    | Admin co-pilot brief generation. Hand-eval prep.            |
| Thu 17 (D9)  | Polish + bug fixes.                                   | Hand-eval 10 disputes. Tune Tier-0 prompt.                  |
| Fri 18 (D10) | End-of-sprint demo + CSV update.                      | Confirm CI green. Tag `sprint-07-end`.                      |

## Definition of "shippable"

- [ ] All 15 mobile rows done
- [ ] All 14 backend rows done
- [ ] Blind reveal logic test passes (both submit, single + timeout)
- [ ] Tier-0 hand-eval: ≥7/10 sample disputes get sensible proposal
- [ ] Cost per dispute ≤ $0.10 average across the eval set
- [ ] PII redaction verified for Tier-0 prompts
- [ ] Admin co-pilot brief renders for the escalated demo dispute
- [ ] `./scripts/coverage.sh` reports ~80% MVP
- [ ] Sprint 8 detail doc reviewed

## Expected PRs (~12-15)

- `feat(prisma): Dispute, DisputeEvidence, Tier0Proposal, AdminCaseBrief`
- `feat(api/reviews): review CRUD + blind reveal cron + min-length`
- `feat(api/reviews): response API + admin removal`
- `feat(api/disputes): dispute state machine + CRUD`
- `feat(api/disputes): evidence collection + upload`
- `feat(api/ai): Tier-0 LLM mediator agent (with cost guard, schema validation, PII redaction)`
- `feat(api/disputes): resolution proposal generation + threshold config`
- `feat(api/disputes): accept/reject logic + escalation flow`
- `feat(api/ai): admin co-pilot case brief generation`
- `feat(mobile): post-completion review prompt + star rating + text`
- `feat(mobile): blind review reveal + response + report`
- `feat(mobile): dispute initiation + evidence upload`
- `feat(mobile): AI proposal screen + accept/reject/escalate`
- `feat(mobile): dispute conversation thread + status tracker + outcome`
