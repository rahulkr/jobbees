# Sprint 4 — Discovery + Bidding + Public Q&A

**Dates:** Mon 27 Jul → Fri 7 Aug 2026 (10 working days)
**Theme:** A tasker opens the app, sees ranked tasks matched to their skills + location, places a bid, and the poster accepts it.
**Hours budget:** ~100 (50 mobile, 50 backend)
**Mid-sprint demo:** Fri 31 Jul
**End-of-sprint demo:** Fri 7 Aug

## Goal in one sentence

By Friday 7 Aug, a tasker logged in sees a ranked feed of tasks they're well-matched to → opens one → asks a public question → places a bid → poster sees the bid via push, opens the app, reviews all bids, accepts one.

## Scope — inventory rows

### Mobile (apps/mobile)

| ID | Item | Call | Hrs | Notes |
| --- | --- | --- | --- | --- |
| 76 | Home feed (ranked) | IN★ | 6 | |
| 77 | Vector-based semantic matching consumer UI | IN★ | 2 | Backend serves; mobile renders |
| 78 | Map view of nearby tasks | IN | 4 | |
| 79 | List view of tasks | IN | 3 | |
| 80 | Filters (category, budget, distance, date) | IN | 4 | |
| 81 | Sort (newest, nearest, highest budget) | IN | 1 | |
| 82 | Saved tasks / favorites | THIN | 2 | |
| 83 | Auto-invite push handling | IN★ | 2 | |
| 84 | Task search bar (text query) | THIN | 2 | |
| 85 | Task share link (deep link) | IN | 1 | |
| 86 | Hide / not interested | THIN | 1 | |
| 87 | Bid placement screen (amount, message, ETA) | IN | 3 | |
| 89 | Own bids list (active, accepted, declined) | IN | 3 | |
| 90 | Edit own bid | IN | 2 | |
| 91 | Withdraw own bid | IN | 1 | |
| 92 | Bid review (poster — list, sort, filter) | IN | 4 | |
| 93 | Accept bid | IN | 2 | |
| 94 | Decline bid | IN | 1 | |
| 96 | Public Q&A under task (questions visible to all taskers) | IN | 6 | Replaces negotiation |
| 97 | Bid expiry handling | IN | 1 | |
| 98 | Bid notifications handling | IN | 1 | |

**Mobile total: ~52h**

### Backend (apps/api)

| ID | Item | Call | Hrs | Notes |
| --- | --- | --- | --- | --- |
| 261 | Bid CRUD | IN | 4 | |
| 262 | Bid state machine | IN | 3 | ACTIVE → WITHDRAWN/ACCEPTED/DECLINED/EXPIRED |
| 263 | Bid notification triggers | IN | 2 | |
| 264 | Bid expiry cron | IN | 2 | |
| 265 | Bid validation (one active per task per tasker) | IN | 2 | |
| 267 | Vector similarity (pgvector cosine top-K) | IN★ | 6 | |
| 268 | Ranked feed algorithm (weighted blend) | IN★ | 8 | Distance × category × win rate × budget × availability |
| 270 | Auto-invite to matched taskers (push on publish) | IN★ | 5 | |
| 271 | Radius expansion / category fallback | THIN | 3 | Mostly admin-driven |
| 272 | Proximity calculation (PostGIS or Haversine) | IN | 3 | Haversine is enough at MVP |
| 273 | Category / skill matching | IN | 3 | |

**Backend total: ~41h**

### Schema additions

- Bid: already in schema. Confirm `@@unique([taskId, taskerId])` (already present line 334)
- Add `SavedTask` model (THIN): `userId`, `taskId`, `savedAt`, `@@id([userId, taskId])`
- Add `HiddenTask` model (THIN): same structure as above for "hide / not interested"
- `TaskQuestion` already in schema (used here for public Q&A)
- `AuditLog` writes on bid accept/decline/expire (already supported by AuditLog model)

## Definition of done

Same as Sprint 1, plus:

- [ ] Vector similarity query uses `Prisma.sql` template with parameterized vector cast (skill §E3)
- [ ] Ranked feed weights documented in `apps/api/src/modules/matching/weights.ts` with comments explaining each factor
- [ ] Auto-invite respects user notification preferences (defer push opt-out logic to S8; for now only invite users who have notifications globally on)
- [ ] Bid CRUD has idempotency middleware (skill §C1)
- [ ] Acceptance test: post a task, verify it shows up in the top-5 ranked feed for at least one seeded tasker within 30 seconds

## Friday demo script (end-of-sprint Fri 7 Aug)

4-5 min screencast:

```
00:00 — "Sprint 4 wrap. Discovery + bidding. Two devices: poster + tasker."
00:15 — Device A (poster): post a new task (using the AI flow from S3).
        Publish.
00:30 — Device B (tasker): pull-to-refresh home feed. New task appears
        near the top — show why (skills match + location).
00:45 — Tap into the task. Show photos, description, location pin,
        budget, scheduled time.
01:00 — Switch to map view. Show task pinned on Sydney map. Use distance
        filter to expand/contract.
01:15 — Switch to list view. Show filters: category, budget, distance,
        date. Show sort: newest, nearest, highest budget.
01:30 — Back to the task. Tap "Ask a question". Type "Do you have
        existing materials or should I bring my own?" Submit.
01:45 — Device A (poster): push notification arrives. Tap → answer the
        question. Submit.
02:00 — Device B (tasker): question + answer now visible. Other taskers
        will also see it.
02:15 — Tap "Place a bid". Enter amount, ETA, optional message. Submit.
02:30 — Device A (poster): push notification for new bid. Tap → bid
        review screen. Show list of bids (just 1 so far). Sort options.
02:45 — Device A: tap the bid → bid detail → tasker profile preview.
        Tap Accept.
03:00 — Device B (tasker): push notification "Your bid was accepted!".
        Bid moves to "Accepted" in own bids list.
03:15 — Show auto-invite: switch to a different seeded tasker and show
        the same task is in their feed because they had matching skills
        (but they didn't bid in time).
03:30 — Show bid expiry: post a task with 24h bid window, show how it
        renders.
03:45 — Coverage report. Stoplight + asks. End.
```

## Risks

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| pgvector cosine queries slow > 100ms | Low | Medium | HNSW index already planned; benchmark on dev data |
| Ranked feed weights need tuning | High | Medium | Build with hand-tuned defaults; expose admin config for runtime tweaks in S9 |
| Auto-invite spams users | Medium | Medium | Cap at 5 invites/day per user; respect global notification off |
| Public Q&A becomes a workaround for off-platform contact | Medium | Medium | Apply same regex detection as messaging (S5); flag suspicious questions to admin queue |
| Vector embeddings out-of-date after task edit | Medium | Low | Re-embed on edit (inventory row 255 in S3); confirm flow |

## Explicitly NOT in scope

- Counter-offer / negotiation — DROPPED (inventory row 95)
- LightGBM ranker — POST (inventory row 269)
- Behavioural fraud detection — POST (inventory row 354)
- Bid coaching nudge — POST (inventory row 88; needs real conversion data)
- Mid-job message to poster — covered by messaging in S5 (inventory row 108)
- Real-time chat policing — THIN, S5 (inventory row 282)

## Day-by-day rough plan

| Day | Mobile | Backend |
| --- | --- | --- |
| Mon 27 Jul (D1) | Home feed scaffolding. List view. | Bid CRUD + state machine. |
| Tue 28 (D2) | Map view (Mapbox SDK). Filters + sort. | Vector similarity (pgvector). |
| Wed 29 (D3) | Task share link + deep link handling. Save/hide. | Ranked feed weighted blend. Proximity calc. |
| Thu 30 (D4) | Search bar (text). Polish discovery. | Auto-invite cron. Category/skill matching. |
| Fri 31 (D5) | Mid-sprint demo + catch-up. | Same. |
| Mon 3 Aug (D6) | Bid placement screen. Own bids list. | Bid notification triggers. Bid expiry cron. |
| Tue 4 (D7) | Edit/withdraw own bid. Bid review (poster). | Bid validation (one active per pair). |
| Wed 5 (D8) | Accept/decline bid. Bid expiry display. | Radius expansion (THIN — admin scaffolding). |
| Thu 6 (D9) | Public Q&A under task. Bid notifications handling. | Public Q&A backend polish. |
| Fri 7 (D10) | End-of-sprint demo + CSV update. | Confirm CI green. Tag `sprint-04-end`. |

## Definition of "shippable"

- [ ] All 21 mobile rows done
- [ ] All 11 backend rows done
- [ ] Home feed loads in < 500ms with 1000 seeded tasks
- [ ] Bid accept end-to-end < 2s including push notification delivery
- [ ] Auto-invite test: post a task, verify 3-5 best-matched taskers receive push within 30s
- [ ] `./scripts/coverage.sh` reports ~48% MVP
- [ ] Sprint 5 detail doc reviewed

## Expected PRs (~13-15)

- `feat(prisma): SavedTask, HiddenTask, Bid finalised`
- `feat(api/bids): bid CRUD + state machine + idempotency`
- `feat(api/bids): bid expiry cron + notification triggers`
- `feat(api/matching): pgvector cosine similarity query`
- `feat(api/matching): ranked feed weighted blend`
- `feat(api/matching): auto-invite to matched taskers`
- `feat(api/matching): proximity calculation (Haversine)`
- `feat(api/qa): public Q&A backend polish + visibility`
- `feat(mobile): home feed (ranked + list + map)`
- `feat(mobile): filters + sort + search`
- `feat(mobile): bid placement + own bids list + edit/withdraw`
- `feat(mobile): bid review for poster + accept/decline`
- `feat(mobile): public Q&A UI`
- `feat(mobile): task share + deep link + save/hide`
