# Sprint 4 — Discovery + Offering + Public Q&A + License verification

> **Note:** Per the 2026-06-12 plan restructure, Sprint 4 absorbed the **License verification module** + offer-time guard + license expiry cron + admin License Review Queue scaffold from Sprint 2. Reason: the offer-time guard is intrinsically tied to offering code; putting it in the same sprint that builds offering is more coherent than splitting the work.

**Dates:** Mon 3 Aug → Fri 14 Aug 2026 (10 working days)
**Theme:** A tasker opens the app, sees ranked jobs matched to their skills + location, makes an offer (gated by license verification for licensed-trade categories), and the client accepts it.
**Hours budget:** ~145 (60 mobile, 56 backend, 5 admin scaffolding, 16 Flutter Web parity, 8 AI-05 feature store THIN per 14 Jun Estimation v1.2 verification)
**Mid-sprint demo:** Fri 7 Aug
**End-of-sprint demo:** Fri 14 Aug

## Goal in one sentence

By Friday 14 Aug, a tasker logged in sees a ranked feed of jobs they're well-matched to → opens one → asks a public question → makes an offer (license guard enforces per ADR 005) → client sees the offer with a "Verified [Trade]" badge via push, opens the app, reviews all offers, accepts one.

## Scope — inventory rows

### Mobile (apps/mobile)

| ID      | Item                                                                                | Call   | Hrs   | Notes                                                                                                                      |
| ------- | ----------------------------------------------------------------------------------- | ------ | ----- | -------------------------------------------------------------------------------------------------------------------------- |
| 76      | Home feed (ranked)                                                                  | IN★    | 6     |                                                                                                                            |
| 77      | Vector-based semantic matching consumer UI                                          | IN★    | 2     | Backend serves; mobile renders                                                                                             |
| 78      | Map view of nearby jobs                                                             | IN     | 4     |                                                                                                                            |
| 79      | List view of jobs                                                                   | IN     | 3     |                                                                                                                            |
| 80      | Filters (category, budget, distance, date)                                          | IN     | 4     |                                                                                                                            |
| 81      | Sort (newest, nearest, highest budget)                                              | IN     | 1     |                                                                                                                            |
| 82      | Saved jobs / favorites                                                              | THIN   | 2     |                                                                                                                            |
| 83      | Auto-invite push handling                                                           | IN★    | 2     |                                                                                                                            |
| 84      | Job search bar (text query)                                                         | THIN   | 2     |                                                                                                                            |
| 85      | Job share link (deep link)                                                          | IN     | 1     |                                                                                                                            |
| 86      | Hide / not interested                                                               | THIN   | 1     |                                                                                                                            |
| 87      | Offer placement screen (amount, message, ETA)                                       | IN     | 3     |                                                                                                                            |
| 89      | Own offers list (active, accepted, declined)                                        | IN     | 3     |                                                                                                                            |
| 90      | Edit own offer                                                                      | IN     | 2     |                                                                                                                            |
| 91      | Withdraw own offer                                                                  | IN     | 1     |                                                                                                                            |
| 92      | Offer review (client — list, sort, filter)                                          | IN     | 4     |                                                                                                                            |
| 93      | Accept offer                                                                        | IN     | 2     |                                                                                                                            |
| 94      | Decline offer                                                                       | IN     | 1     |                                                                                                                            |
| 96      | Public Q&A under job (questions visible to all taskers)                             | IN     | 6     | Replaces negotiation                                                                                                       |
| 97      | Offer expiry handling                                                               | IN     | 1     |                                                                                                                            |
| 98      | Offer notifications handling                                                        | IN     | 1     |                                                                                                                            |
| **41**  | **License upload — per-category, only for licensed-trade categories** (per ADR 005) | **IN** | **5** | Tasker selects category, uploads license photo, types license number + issuing state + expiry → goes to admin review queue |
| **531** | **Licensed-trade category selector with deeplink**                                  | **IN** | **2** | Offer screen blocks unlicensed taskers on licensed-trade jobs with "License required" CTA → deeplinks to upload screen     |

**Mobile total: ~59h** (License upload UI adds 7h)

### Backend (apps/api)

| ID      | Item                                                                              | Call   | Hrs   | Notes                                                                                                                                                                                                                                                                                                                                                                                                            |
| ------- | --------------------------------------------------------------------------------- | ------ | ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 261     | Offer CRUD                                                                        | IN     | 4     |                                                                                                                                                                                                                                                                                                                                                                                                                  |
| 262     | Offer state machine                                                               | IN     | 3     | ACTIVE → WITHDRAWN/ACCEPTED/DECLINED/EXPIRED                                                                                                                                                                                                                                                                                                                                                                     |
| 263     | Offer notification triggers                                                       | IN     | 2     |                                                                                                                                                                                                                                                                                                                                                                                                                  |
| 264     | Offer expiry cron                                                                 | IN     | 2     |                                                                                                                                                                                                                                                                                                                                                                                                                  |
| 265     | Offer validation (one active per job per tasker)                                  | IN     | 2     |                                                                                                                                                                                                                                                                                                                                                                                                                  |
| 267     | Vector similarity (pgvector cosine top-K)                                         | IN★    | 6     |                                                                                                                                                                                                                                                                                                                                                                                                                  |
| 268     | Ranked feed algorithm (weighted blend)                                            | IN★    | 8     | Distance × category × win rate × budget × availability                                                                                                                                                                                                                                                                                                                                                           |
| 270     | Auto-invite to matched taskers (push on publish)                                  | IN★    | 5     |                                                                                                                                                                                                                                                                                                                                                                                                                  |
| 271     | Radius expansion / category fallback                                              | THIN   | 3     | Mostly admin-driven                                                                                                                                                                                                                                                                                                                                                                                              |
| 272     | Proximity calculation (PostGIS or Haversine)                                      | IN     | 3     | Haversine is enough at MVP                                                                                                                                                                                                                                                                                                                                                                                       |
| 273     | Category / skill matching                                                         | IN     | 3     |                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **240** | **License verification module (per-category, manual admin review)** (per ADR 005) | **IN** | **8** | License upload endpoint, state machine (PENDING → APPROVED / REJECTED / EXPIRED), AuditLog writes on every transition, reviewer notes capture. **Backend validates `licenseType` against `ALLOWED_LICENSE_TYPES[categoryId]` from `packages/types/src/licenses.ts` (added in Sprint 2) on every insert/update — rejects anything not in the allowed list.** Mobile uses the same constant to drive the dropdown. |
| **532** | **Offer-time license guard (incl. conditional Builder rule)** (per ADR 005)       | **IN** | **4** | `POST /offers` runs License guard: unconditional categories (Plumbing/Electrical/etc.) always require license; Builder requires license when fixed-price offer ≥ $5K AUD OR any hourly offer on Builder. Returns 403 LICENSE_REQUIRED with structured reason payload                                                                                                                                             |
| **533** | **License expiry cron + reminder emails**                                         | **IN** | **2** | Daily cron: 14d / 7d / 1d advance reminders → tasker email; expiresAt < now → auto-transition to EXPIRED + AuditLog + email                                                                                                                                                                                                                                                                                      |

**Backend total: ~55h** (License module + offer guard + expiry cron adds 14h)

### Admin scaffolding (apps/admin)

| ID      | Item                                                     | Call   | Hrs   | Notes                                                                                                                                                                                                   |
| ------- | -------------------------------------------------------- | ------ | ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **534** | **License Review Queue (scaffold only — full UI in S9)** | **IN** | **5** | Admin views PENDING License rows, cross-checks against AU state register (NSW Fair Trading etc. — URL link), approve/reject/needs-more, AuditLog with actorId + register URL recorded in reviewer notes |

**Admin total: ~5h**

### Flutter Web parity (added per founder direction 14 Jun 2026)

| ID    | Item                                                                                                                                                                                                                                                                                                                                                   | Call | Hrs | Notes                                                                                                                                   |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---- | --- | --------------------------------------------------------------------------------------------------------------------------------------- |
| FW-13 | **Web parity — ranked feed, map view (Google Maps JS), list view, filters, sort, saved jobs, search bar, share link, hide-job**                                                                                                                                                                                                                        | IN   | 7   | Shareable web URLs for ranked feed make the SEO surface meaningful for taskers + clients.                                               |
| FW-14 | **Web parity — offer placement, offers list, edit/withdraw offer, offer review (client), accept/decline, offer expiry handling, public Q&A**                                                                                                                                                                                                           | IN   | 6   | Offer creation on web is identical to mobile; web also picks up the public Q&A surface naturally as part of indexable job pages.        |
| FW-15 | **Web parity — license upload UI + licensed-trade category selector** (per ADR 005)                                                                                                                                                                                                                                                                    | IN   | 3   | Web file picker for license image; same backend `/licenses/upload` endpoint. License badge rendering shared with public tasker profile. |
| AI-05 | **Feature store (matching + pricing ML) — THIN** (re-scoped IN per 14 Jun Estimation v1.2 verification — was V2; THIN call) — Postgres-backed feature table. Pre-computed features per tasker (win rate, response time, completion rate, average rating, recent skill changes). Nightly BullMQ refresh. Read by the composite ranker (B-04, Sprint 4). | THIN | 8   | Estimate v1.2 marks THIN — minimal feature set at MVP. LightGBM ranker / learned ranking remains POST.                                  |

**Flutter Web parity + ML store total: ~24h**

### Schema additions

- Offer: already in schema. Confirm `@@unique([jobId, taskerId])` (already present line 334)
- Add `SavedJob` model (THIN): `userId`, `jobId`, `savedAt`, `@@id([userId, jobId])`
- Add `HiddenJob` model (THIN): same structure as above for "hide / not interested"
- `JobQuestion` already in schema (used here for public Q&A)
- `AuditLog` writes on offer accept/decline/expire (already supported by AuditLog model)
- **New `License` model (per ADR 005):**

  ```prisma
  model License {
    id              String        @id // cuid2
    userId          String
    user            User          @relation(fields: [userId], references: [id], onDelete: Cascade)
    categoryId      String
    category        Category      @relation(fields: [categoryId], references: [id])
    licenseType     String        // "electrical-contractor", "plumber", "builder", etc.
    licenseNumber   String        // From AU state register
    issuingState    String        // "NSW", "VIC", "QLD", etc.
    expiresAt       DateTime
    uploadedBlobUrl String        // Photo of physical license
    status          LicenseStatus @default(PENDING)
    reviewedAt      DateTime?
    reviewerId      String?
    reviewer        User?         @relation("LicenseReviews", fields: [reviewerId], references: [id])
    reviewerNotes   String?
    createdAt       DateTime      @default(now())

    @@unique([userId, categoryId])  // one license per tasker per category
    @@index([userId])
    @@index([categoryId])
    @@index([status])
    @@index([expiresAt])
  }

  enum LicenseStatus { PENDING APPROVED REJECTED EXPIRED }
  ```

- Note: `Category.requiresLicense` + `Category.licenseRequiredOverCents` were seeded in Sprint 2; Sprint 4 wires up the offer-time guard that consumes them.

## Definition of done

Same as Sprint 1, plus:

- [ ] Vector similarity query uses `Prisma.sql` template with parameterized vector cast (skill §E3)
- [ ] Ranked feed weights documented in `apps/api/src/modules/matching/weights.ts` with comments explaining each factor
- [ ] Auto-invite respects user notification preferences (defer push opt-out logic to S8; for now only invite users who have notifications globally on)
- [ ] Offer CRUD has idempotency middleware (skill §C1)
- [ ] Acceptance test: post a job, verify it shows up in the top-5 ranked feed for at least one seeded tasker within 30 seconds
- [ ] License offer guard test (per ADR 005): tasker without APPROVED plumbing License on a Plumbing job (requiresLicense=true) → 403 LICENSE_REQUIRED with reason `ALWAYS_REQUIRED`
- [ ] License offer guard test — Builder conditional rule: fixed-price offer of $4,000 on Builder → allowed (under $5K threshold); fixed-price offer of $7,500 → 403 with reason `OVER_THRESHOLD`; hourly offer on Builder → 403 with reason `HOURLY_ON_CONDITIONAL_CATEGORY`
- [ ] License expiry cron test: license with expiresAt < now → auto EXPIRED + email + AuditLog; 14d/7d/1d advance reminders fire idempotently
- [ ] Admin license review queue test: admin can approve / reject / request more info; AuditLog records actorId + cross-checked register URL in reviewer notes
- [ ] License blob storage namespaced under `licenses/{userId}/{licenseId}/...` per skill §F4 (clean DSR delete + quantifiable breach scope)
- [ ] `License.licenseType` validated against `ALLOWED_LICENSE_TYPES[categoryId]` shared constant per ADR 005 — backend rejects any slug not in the allowed list with 400 `INVALID_LICENSE_TYPE`. Mobile dropdown sourced from the same constant. Admin review queue renders the display label from the constant.

## Friday demo script (end-of-sprint Fri 14 Aug)

5-6 min screencast:

```
00:00 — "Sprint 4 wrap. Discovery + offering + license verification.
        Two devices: client + tasker."

00:15 — Device A (client): post a NON-licensed job (e.g., cleaning)
        using the AI flow from S3. Publish.

00:30 — Device B (tasker, NO licenses): pull-to-refresh home feed. New
        job appears near the top — show why (skills match + location).

00:45 — Tap into the job. Map view, list view, filters (category,
        budget, distance, date), sort options. Place offer. Submit.

01:15 — Device A (client): push notification for new offer. Open offer
        review screen. Sort. Tap Accept.

01:30 — Device B (tasker): "Your offer was accepted!" notification.

01:45 — Now switch to LICENSE flow. Device A (client): post a PLUMBING
        job. Publish.

02:00 — Device B (tasker, no plumbing license): tap the plumbing job →
        tap "Make an offer" → offer screen blocked with banner: "This job
        requires a licensed plumber. Add your plumbing licence to make
        an offer." Deeplink button.

02:20 — Device B (tasker): tap deeplink → land on License upload screen.
        Pick "Plumbing" category. Upload license photo. Type license
        number (e.g., L12345). Issuing state: NSW. Expiry: 2027-03-14.
        Submit. "Pending admin review" status.

02:50 — Switch to admin (scaffold-level License Review Queue): new
        PENDING row appears. Open it. View uploaded license photo +
        license number + issuing state + expiry. Click "Verify against
        NSW Fair Trading" link (opens public register search in browser).
        Approve. AuditLog row written with admin actorId + register URL.

03:20 — Device B (tasker): pull-to-refresh. License status: APPROVED.
        Return to plumbing job. Offer screen now enabled. Place offer.

03:35 — Device A (client): offer notification → review screen → offer
        shows "Verified Plumber" badge next to tasker name. Accept.

03:55 — Now demo the CONDITIONAL Builder rule. Device A (client): post
        a "build me a deck" job in the Builder category. Publish.

04:10 — Device B (tasker, has plumbing license but NO builder license):
        offer $4,000 (fixed price). Allowed — under $5K NSW threshold.
        Withdraw offer. Offer $7,500. Blocked: "License required because
        your offer of $7,500 is over the $5,000 NSW threshold."

04:35 — Offer hourly $80/hr on the same Builder job. Blocked: "Hourly
        offers on Builder jobs require a licensed builder regardless of
        estimated value."

04:55 — Show license expiry cron in action: backdate a license expiresAt
        by 1 day → run cron manually → status auto-transitions to
        EXPIRED → tasker can no longer make an offer on that category.
        AuditLog row + email simulated.

05:15 — Coverage report. Stoplight + asks. End.

05:30 — "Sprint 5 starts Monday: messaging + payments core + OTP swap."
```

## Risks

| Risk                                                     | Likelihood | Impact | Mitigation                                                                             |
| -------------------------------------------------------- | ---------- | ------ | -------------------------------------------------------------------------------------- |
| pgvector cosine queries slow > 100ms                     | Low        | Medium | HNSW index already planned; benchmark on dev data                                      |
| Ranked feed weights need tuning                          | High       | Medium | Build with hand-tuned defaults; expose admin config for runtime tweaks in S9           |
| Auto-invite spams users                                  | Medium     | Medium | Cap at 5 invites/day per user; respect global notification off                         |
| Public Q&A becomes a workaround for off-platform contact | Medium     | Medium | Apply same regex detection as messaging (S5); flag suspicious questions to admin queue |
| Vector embeddings out-of-date after job edit             | Medium     | Low    | Re-embed on edit (inventory row 255 in S3); confirm flow                               |

## Explicitly NOT in scope

- Counter-offer / negotiation — DROPPED (inventory row 95)
- LightGBM ranker — POST (inventory row 269)
- Behavioural fraud detection — POST (inventory row 354)
- Offer coaching nudge — POST (inventory row 88; needs real conversion data)
- Mid-job message to client — covered by messaging in S5 (inventory row 108)
- Real-time chat policing — THIN, S5 (inventory row 282)

## Day-by-day rough plan

| Day            | Mobile                                                                                                 | Backend                                                                                                               |
| -------------- | ------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| Mon 3 Aug (D1) | Home feed scaffolding. List view.                                                                      | Offer CRUD + state machine. License model + LicenseStatus enum migration.                                             |
| Tue 4 (D2)     | Map view (Google Maps SDK). Filters + sort.                                                            | Vector similarity (pgvector). License upload endpoint.                                                                |
| Wed 5 (D3)     | Job share link + deep link handling. Save/hide.                                                        | Ranked feed weighted blend. Proximity calc. License approval state machine + AuditLog.                                |
| Thu 6 (D4)     | Search bar (text). Polish discovery. **License upload UI (row 41).**                                   | Auto-invite cron. Category/skill matching. **License expiry cron + 14d/7d/1d reminders.**                             |
| Fri 7 (D5)     | Mid-sprint demo + catch-up.                                                                            | Same.                                                                                                                 |
| Mon 10 (D6)    | Offer placement screen. Own offers list. **Licensed-trade category selector with deeplink (row 531).** | Offer notification triggers. Offer expiry cron. **Offer-time license guard with conditional Builder rule (row 532).** |
| Tue 11 (D7)    | Edit/withdraw own offer. Offer review (client). License status screen.                                 | Offer validation (one active per pair). License guard tests.                                                          |
| Wed 12 (D8)    | Accept/decline offer. Offer expiry display. "Verified [Trade]" badges.                                 | Radius expansion (THIN — admin scaffolding). **Admin License Review Queue endpoint (row 534).**                       |
| Thu 13 (D9)    | Public Q&A under job. Offer notifications handling. **Admin License Review Queue scaffold UI.**        | Public Q&A backend polish. AuditLog write coverage check.                                                             |
| Fri 14 (D10)   | End-of-sprint demo + CSV update.                                                                       | Confirm CI green. Tag `sprint-04-end`.                                                                                |

## Definition of "shippable"

- [ ] All 23 mobile rows done (incl. License upload + category selector)
- [ ] All 14 backend rows done (incl. License module + offer guard + expiry cron)
- [ ] 1 admin scaffold row done (License Review Queue minimal UI)
- [ ] Home feed loads in < 500ms with 1000 seeded jobs
- [ ] Offer accept end-to-end < 2s including push notification delivery
- [ ] Auto-invite test: post a job, verify 3-5 best-matched taskers receive push within 30s
- [ ] License guard tests green for all 3 reasons (`ALWAYS_REQUIRED` / `OVER_THRESHOLD` / `HOURLY_ON_CONDITIONAL_CATEGORY`)
- [ ] License expiry cron test green
- [ ] `./scripts/coverage.sh` reports ~48% MVP
- [ ] Sprint 5 detail doc reviewed

## Expected PRs (~16-19)

- `feat(prisma): SavedJob, HiddenJob, Offer finalised, License + LicenseStatus enum`
- `feat(api/offers): offer CRUD + state machine + idempotency`
- `feat(api/offers): offer expiry cron + notification triggers`
- `feat(api/offers): offer-time license guard (incl. conditional Builder rule per ADR 005) + structured 403 response`
- `feat(api/license): License module — upload endpoint + admin approval state machine + AuditLog`
- `feat(api/license): license expiry cron + 14d/7d/1d reminders`
- `feat(api/matching): pgvector cosine similarity query`
- `feat(api/matching): ranked feed weighted blend`
- `feat(api/matching): auto-invite to matched taskers`
- `feat(api/matching): proximity calculation (Haversine)`
- `feat(api/qa): public Q&A backend polish + visibility`
- `feat(mobile): home feed (ranked + list + map)`
- `feat(mobile): filters + sort + search`
- `feat(mobile): offer placement + own offers list + edit/withdraw`
- `feat(mobile): offer review for client + accept/decline`
- `feat(mobile): license upload UI + licensed-trade category selector with deeplink`
- `feat(mobile): public Q&A UI`
- `feat(mobile): job share + deep link + save/hide`
- `feat(admin): License Review Queue scaffold (full UI in S9)`
