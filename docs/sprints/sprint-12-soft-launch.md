# Sprint 12 — Soft launch + first real users + retrospective

**Dates:** Mon 23 Nov → Fri 4 Dec 2026 (10 working days)
**Theme:** A real Sydney tasker, in a real suburb, completes a real task posted by a real poster, with real money flowing through Stripe live mode. The MVP exists in the world.
**Hours budget:** ~50 (split across launch ops, monitoring, bug-fix, retrospective)
**Mid-sprint demo:** Fri 27 Nov
**End-of-sprint demo:** Fri 4 Dec (the launch video)

**🚨 Stripe goes LIVE this sprint.** One-way decision per the Stripe live-mode toggle. Cannot easily reverse. Switch-checklist must be reviewed by eng lead + client before flipping.

## Goal in one sentence

By Friday 27 Nov, JOBBees has 30-50 real taskers onboarded in one Sydney suburb, the first real poster-tasker transaction with real money has completed, both sides have left reviews, the tax invoice is real, and we have a recorded "first real task" launch video.

## Scope

### Launch ops

| Item                                                    | Hrs | Notes                                                                                        |
| ------------------------------------------------------- | --- | -------------------------------------------------------------------------------------------- |
| Pick the launch suburb                                  | 1   | Newtown, Surry Hills, Bondi? Population density + tasker availability + transport            |
| Recruit 30-50 taskers via manual outreach               | 8   | LinkedIn, Facebook groups, Gumtree-replacement posts, friends. Admin invitation tool from S9 |
| Onboard each tasker (admin walks through KYC + Connect) | 8   | Synthetic supply seeding — inventory row 509 says MANUAL — confirmed                         |
| Stripe live-mode switch + checklist review              | 3   | Eng lead + client both sign off                                                              |
| First real poster recruited + onboarded                 | 1   | Could be a friend, the client, or via referral from the taskers                              |
| First real task posted                                  | 1   | The launch moment                                                                            |
| First real task completed                               | n/a | Hands-off — watch + monitor                                                                  |
| Record + edit launch video                              | 3   | The Sprint 12 demo IS this                                                                   |

### Monitoring + daily ops

| Item                                                    | Hrs | Notes                   |
| ------------------------------------------------------- | --- | ----------------------- |
| Daily 30-min standup (yourself + client)                | 5   | 10 working days × 30min |
| Monitor App Insights — error rate, latency, exceptions  | 5   | Check 3× daily          |
| Monitor Cloudflare WAF — blocks, anomalies              | 2   | Daily                   |
| Monitor Stripe webhook delivery — failures, retries     | 2   | Daily                   |
| Cost tracking — Azure + Cloudflare + LLMs + Stripe fees | 2   | Daily                   |
| Bug-fix budget — what breaks live, fix live             | 12  | Reserved                |

### End-of-MVP audit

| Item                                                                       | Hrs | Notes                   |
| -------------------------------------------------------------------------- | --- | ----------------------- |
| Run `./scripts/coverage.sh --remaining`                                    | 0.5 | Should be ≤2% remaining |
| Document any unfinished IN/IN★ rows in `docs/sprints/post-mvp-deferred.md` | 2   | Justification per row   |
| Re-run `security-review` skill across entire repo                          | 2   | Final check             |
| Re-run Semgrep + CodeQL + Trivy CVE                                        | 1   | Final clean scan        |
| Verify all audit docs have current "Last reviewed" dates                   | 1   |                         |
| Verify all ADRs reflect actual built state                                 | 1   |                         |
| Update PROJECT_CONTEXT.md with launch state                                | 1   |                         |

### Retrospective

| Item                                      | Hrs | Notes                                                         |
| ----------------------------------------- | --- | ------------------------------------------------------------- |
| Draft `docs/sprints/retrospective.md`     | 3   | What worked, what didn't, surprises, lessons                  |
| Draft `docs/sprints/post-mvp-roadmap.md`  | 2   | What's next: scaling, POST features, additional suburbs, etc. |
| Hand-off doc: how to onboard a future dev | 2   |                                                               |
| Client wrap meeting                       | 1   |                                                               |

**Sprint total: ~75h** (exceeds 50h budget — soft-launch hours are unpredictable; budget is aspirational, not a cap)

## Decision gate — Day 1

**Switch Stripe from test mode to live mode.**

Checklist (every box must be ticked before flipping):

- [ ] Stripe Connect Express account verified for production
- [ ] AU business registration documented (ABN, company name) in Stripe
- [ ] Stripe live keys stored in Key Vault (NEVER in `.env.local`)
- [ ] Webhook endpoint registered with Stripe live mode pointing to production URL
- [ ] Live webhook secret in Key Vault
- [ ] Test card numbers replaced — clear `STRIPE_TEST_KEY` from prod env
- [ ] Idempotency tested end-to-end with live mode (one $0.50 test transaction)
- [ ] Refund flow tested in live mode
- [ ] Real bank account configured for platform payout
- [ ] AML/AML check for the business completed (Stripe will prompt)
- [ ] RCTI agreement template signed by counsel
- [ ] Tax advisor confirmed ATO reporting works on real data
- [ ] Eng lead has manually reviewed every payment/payout/tax file once more
- [ ] Client has signed off in writing on the live-mode switch (email or doc)

If any box is unchecked, do NOT flip. Stay in test mode until resolved.

## Definition of done

- [ ] Live Stripe switch completed cleanly with no rollback
- [ ] 30-50 real taskers onboarded
- [ ] At least 5 real tasks posted, at least 1 completed end-to-end with real payment
- [ ] Tax invoice generated for the first real transaction (must be ATO-compliant)
- [ ] No P0 incidents during launch week
- [ ] All P1 bugs found during launch fixed
- [ ] Retrospective written
- [ ] Post-MVP roadmap written
- [ ] Coverage script reports ≥98% IN/IN★ done, with `post-mvp-deferred.md` covering the rest

## Friday demo script (end-of-sprint Fri 27 Nov — the launch video)

This isn't a screencast — it's the **launch video**. 3-4 min, polished. Send to client + (with permission) post publicly.

```
00:00 — Title card: "JOBBees — first real task. Sydney, 2026."
00:08 — Drone shot or street-level of the launch suburb (Newtown
        say — terrace houses, café strip).
00:15 — Voice-over: "On day one, a person in Sydney needed help
        assembling some Ikea furniture. Within an hour, they had a
        verified tasker on the way."
00:30 — Real footage: poster opens app on iPhone (real person, real
        phone). Posts a task using AI vision: takes photo of unopened
        Ikea box. App auto-categorises, suggests budget.
00:50 — Cut to second real person — a tasker in the area — receiving
        the push notification, opening the app, seeing the matched
        task on their ranked feed, placing a bid.
01:10 — Poster accepts the bid. Chat exchange (sped up).
01:25 — Tasker arrives at the address — geofence check-in.
01:35 — Time-lapse of the task being completed.
01:50 — Tasker uploads 2 photos + ticks the checklist. Hits Complete.
02:00 — Poster reviews the photos. Auto-capture fires. Payment goes
        through. RCTI PDF arrives on tasker's phone.
02:15 — Both leave reviews. Tasker says "Easy job, fair poster." Poster
        says "Great work, would book again." Reviews go visible
        simultaneously.
02:30 — Voice-over: "30 minutes from post to complete. AI-matched.
        Real money. Compliant tax. Live in Sydney from today."
02:45 — Cut to client + you: "Sprint 12. MVP complete. 9 IT audit
        controls, 6 custom AI skills, 18 Semgrep rules, 522 features
        scoped, ~945 hours over 26 weeks."
03:00 — Title card: "JOBBees. Find help. Be the help."
03:10 — End.
```

## Risks

| Risk                                                                | Likelihood | Impact   | Mitigation                                                                                 |
| ------------------------------------------------------------------- | ---------- | -------- | ------------------------------------------------------------------------------------------ |
| Stripe live switch reveals a config bug                             | Medium     | Critical | Test in staging with the same flow before flipping; have rollback plan                     |
| First real payment fails                                            | Medium     | Critical | Manual monitoring during first 24h; engineer on-call                                       |
| Tasker no-shows on first real task — bad first impression           | Medium     | High     | Personally vet the first 5 taskers; have a backup tasker on standby                        |
| Cloudflare WAF blocks real users mid-launch                         | Low        | High     | Monitor block log daily; whitelist if false positives                                      |
| ATO reporting bug found in live data                                | Medium     | Critical | Tax advisor reviews the first month's report; document any issues                          |
| Client wants to push major launch announcement before MVP is stable | Medium     | Medium   | Soft-launch is intentionally low-key; full marketing in post-MVP                           |
| Burn rate exceeds expected (Azure spend)                            | Medium     | Medium   | Daily cost monitoring; alert at $X/day; downscale if needed                                |
| Apple / Play store rejects launch build at last minute              | Low        | High     | Have a stable build approved before mid-sprint; minor patches can be pushed via TestFlight |

## Explicitly NOT in scope

- Multi-suburb launch — single Sydney suburb only at MVP
- Marketing campaigns / paid acquisition — POST
- New features — anything not in the inventory
- Performance optimisation beyond what's measured — POST unless P0 issue
- Second-language support — POST (inventory row 187)
- Press release — coordinate with client; if happens, it's a separate workstream

## Day-by-day rough plan

| Day          | Focus                                                                                                         |
| ------------ | ------------------------------------------------------------------------------------------------------------- |
| Mon 16 (D1)  | **Stripe live-mode switch.** Checklist review + flip. First $0.50 test live transaction (refund immediately). |
| Tue 17 (D2)  | Start tasker outreach — LinkedIn, Facebook, Gumtree-replacement posts. Goal: 10 leads by EOD.                 |
| Wed 18 (D3)  | Onboard first 5 taskers via admin tool. Walk each through KYC + Connect personally.                           |
| Thu 19 (D4)  | Onboard next 10 taskers. Daily monitoring kicks in.                                                           |
| Fri 20 (D5)  | Mid-sprint demo: "we have 15 verified taskers ready."                                                         |
| Mon 23 (D6)  | First real poster recruited (client or friend). First real task posted. Watch carefully.                      |
| Tue 24 (D7)  | Onboard remaining taskers (up to 50). First real task completes. Record key moments.                          |
| Wed 25 (D8)  | Bug-fix from real-world feedback. Monitor + iterate.                                                          |
| Thu 26 (D9)  | End-of-MVP audit: coverage script, security scans, audit doc reviews. Retrospective drafting.                 |
| Fri 27 (D10) | Launch video record + edit. Final wrap call. Tag `sprint-12-end` AND `mvp-v1.0`.                              |

## Definition of "MVP done"

- [ ] Coverage ≥98%, gaps documented in `post-mvp-deferred.md`
- [ ] All P0 incidents resolved
- [ ] Live mode operational with no manual interventions for 48h
- [ ] First real transaction completed end-to-end with real money
- [ ] Tax invoice + RCTI generated, both ATO-compliant
- [ ] Retrospective document committed
- [ ] Post-MVP roadmap document committed
- [ ] Hand-off doc committed (`docs/sprints/onboarding-new-dev.md`)
- [ ] Sprint plan archive: rename `docs/sprints/PLAN.md` → `docs/sprints/PLAN-mvp-v1.md` for historical reference
- [ ] Launch video uploaded + sent to client
- [ ] Tagged: `mvp-v1.0` on `main` branch

## Expected PRs (~8-12, smaller)

- `chore(stripe): switch to live mode + production webhook + Key Vault keys`
- `chore(infra): cost monitoring alerts + daily report cron`
- `fix(*): live-only bug fixes (5-8 small PRs)`
- `docs(retrospective): MVP retrospective + lessons learned`
- `docs(roadmap): post-MVP roadmap (features deferred, scaling plans)`
- `docs(handoff): onboarding-new-dev.md`
- `docs(deferred): post-mvp-deferred.md (any IN/IN★ rows that didn't ship)`
- `chore(audit): final audit doc owner assignments + last-reviewed dates`
- `chore(docs): PROJECT_CONTEXT.md final launch-state update`
- `chore(release): tag mvp-v1.0`

## After MVP

The plan ends here. Post-MVP work goes into a fresh planning document (`docs/sprints/post-mvp-PLAN.md`) and is scoped separately. The 12 build sprints have done their job.

The repo at this point should be:

- Self-explanatory enough that a new dev could onboard in 1 day with `PROJECT_CONTEXT.md` + a 30-min walkthrough
- Compliant enough that an IT auditor finds no major gaps
- Operationally sound enough that you can take a 2-week holiday and the platform keeps running
- Well-loved enough that the first real taskers want to keep using it

That's the bar. See you on the other side.
