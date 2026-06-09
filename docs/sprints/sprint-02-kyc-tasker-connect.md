# Sprint 2 — KYC + Tasker upgrade + Stripe Connect onboarding

**Dates:** Mon 29 Jun → Fri 10 Jul 2026 (10 working days)
**Theme:** Get a poster into "verified tasker with held-funds banner, Connect onboarding live" so Sprint 3's first task can earn real money.
**Hours budget:** ~85 (40 mobile, 40 backend, 5 admin scaffolding)
**Mid-sprint demo:** Fri 3 Jul
**End-of-sprint demo:** Fri 10 Jul

## Goal in one sentence

By Friday 10 Jul, a user can sign up as poster → tap "Become a tasker" → complete KYC (via Didit OR via the manual review path) → enter ABN → land in Stripe Connect onboarding → see a persistent held-funds banner until Connect is complete.

## Scope — inventory rows

### Mobile (apps/mobile)

| ID | Item | Call | Hrs | Notes |
| --- | --- | --- | --- | --- |
| 15 | Poster → Tasker upgrade flow (one-way only) | IN | 4 | Triggers KYC + Connect onboarding |
| 21 | ID document upload (license/passport) | IN | 4 | Photo + crop |
| 22 | Selfie / liveness check | IN | 3 | Didit SDK OR upload only on manual path |
| 23 | Stripe Identity webview | IN | 3 | Or Didit webview, depending on KYC decision |
| 24 | ABN entry + ABR lookup UI | IN | 3 | Tasker-only |
| 25 | KYC status screen (pending/approved/rejected) | IN | 2 | |
| 26 | Manual review prompt | IN | 1 | |
| 27 | KYC re-submission flow | IN | 2 | |
| 35 | Tasker profile setup wizard (multi-step) | IN | 5 | |
| 36 | Bio / about me | IN | 1 | |
| 37 | Skills selection (categories + tags) | IN | 3 | |
| 38 | Service areas (suburb / radius picker) | IN | 3 | |
| 39 | Hourly rate / minimum task fee | IN | 1 | |
| 40 | Profile photo + cover image upload | IN | 2 | |
| 41 | Certifications / licenses upload | THIN | 2 | Optional render only |
| 44 | Stripe Connect onboarding entry | IN | 2 | |
| 45 | Held-funds banner | IN | 2 | Persistent until Connect complete |
| 46 | Connect reminder cadence — mobile rendering | IN | 2 | 24h / 72h / 7d |
| 47 | Public tasker profile (visible to posters) | IN | 3 | |
| 48 | Portfolio / previous work photos | THIN | 2 | Upload + render only |
| 49 | Reviews received display | IN | 2 | Empty state for now |

**Mobile total: ~50h**

### Backend (apps/api)

| ID | Item | Call | Hrs | Notes |
| --- | --- | --- | --- | --- |
| 240 | KYC orchestration (Didit OR manual queue) | IN | 6 | Implementation forks per ADR 005 |
| 241 | ABN + ABR lookup integration | IN | 3 | https://abr.business.gov.au/ |
| 244 | Poster→Tasker upgrade backend (one-way) | IN | 3 | State change, triggers KYC + Connect requirements |
| 292 | Stripe Connect Express integration | IN | 12 | The big one this sprint |
| 293 | Connect webhook handlers | IN | 6 | account.updated, account.application.authorized, etc. |
| 294 | Connect onboarding status tracking | IN | 4 | Pending → restricted → complete state transitions |
| 295 | Held-funds calculation per tasker | IN | 3 | Sum of captured-but-not-released amounts |

**Backend total: ~37h**

### Admin scaffolding (apps/admin)

| ID | Item | Call | Hrs | Notes |
| --- | --- | --- | --- | --- |
| 431 | KYC review queue (scaffold only — full UI in S9) | IN | 4 | Just enough to approve/reject if manual path picked |
| 432 | Connect onboarding tracker (scaffold) | IN | 3 | List view of Connect statuses |

**Admin total: ~7h**

### Schema additions

- `Didit` path: add to User model: `kycStatus` (enum already exists), `kycSessionId String?`, `kycVerifiedAt DateTime?`, `kycProvider String? // "didit" | "manual"`, `documentType String? // "passport" | "license" — never the number`
- `Manual` path: add `KycSubmission` model: `id`, `userId`, `documentBlobUrl`, `selfieBlobUrl`, `submittedAt`, `reviewedAt`, `reviewerId`, `decision: enum APPROVED/REJECTED/NEEDS_MORE`, `reviewerNotes`
- Add to User model: `stripeConnectAccountId String?`, `connectStatus ConnectStatus @default(NOT_STARTED)`, `connectOnboardedAt DateTime?`
- Add to User model: `abn String?`, `abnVerifiedAt DateTime?`, `noAbnReason String?`
- New `ServiceArea` model (from FUTURE MODELS): `userId`, `suburb`, `postcode`, `radiusKm Int @default(15)`, composite `@@unique([userId, suburb])`

## Decision gate — Day 1

**KYC vendor: Didit OR manual review.** Defaults to manual if no decision by Day 1 EOD.

Record in `docs/adrs/005-kyc-strategy.md`:

| If Didit | If manual |
| --- | --- |
| Integrate Didit Flutter SDK in mobile | Build admin review queue (S9 scaffold this sprint) |
| Backend handles HMAC webhook from Didit | Backend stores blob URLs + review state machine |
| Store only `diditSessionId`, status, timestamp, document type | Store blob URLs (Azure Blob in S10, local FS until then) |
| ~13h savings vs manual | More PII handling — extra audit doc updates needed |
| 500 free verifications/month | No vendor cost, but admin time per verification |
| ADR records the choice + reversal cost (~10h) | ADR records the choice + Didit fallback plan |

## Definition of done

Same as Sprint 1, plus:

- [ ] If Didit path: HMAC signature verified on every Didit webhook (skill §H5)
- [ ] If manual path: KYC blobs stored with retention policy in `docs/audit/data-retention-policy.md`
- [ ] No raw government ID numbers persisted on JOBBees side (passport number, license number) — even on manual path, store doc images only, not the typed-in number
- [ ] AuditLog write on every KYC state transition (skill §I1)
- [ ] AuditLog write on every Connect state transition

## Friday demo script (end-of-sprint Fri 10 Jul)

3-5 minute screencast:

```
00:00 — "Sprint 2 wrap. Goal: poster becomes verified tasker with Connect
        onboarding running. Here it goes."
00:15 — Open app as logged-in poster (from Sprint 1).
00:30 — Tap profile → "Become a tasker" CTA.
00:50 — One-way confirmation dialog: "This can't be reversed. Continue?"
01:00 — KYC flow launches. Show doc upload + selfie + liveness (Didit path)
        OR upload doc + selfie (manual path).
01:40 — Show "KYC status: pending" screen.
01:50 — Cut to admin: KYC review queue. Approve the request.
02:00 — Mobile: pull-to-refresh → "KYC approved" → status updates.
02:15 — ABN entry screen. Enter test ABN. ABR lookup populates business
        name. Submit.
02:35 — Tasker profile wizard: bio, skills (multi-select chips), service
        areas (suburb picker with radius slider), hourly rate, profile
        photo upload.
03:10 — Show held-funds banner appearing at top of tasker home: "$0 held
        — complete Stripe onboarding to receive payouts" with Continue CTA.
03:20 — Tap CTA → Stripe Connect webview launches.
03:30 — Stripe Connect onboarding form (test data). Complete it.
03:45 — Return to app → Connect status webhook fires → banner updates
        to "$0 held — onboarding complete".
04:00 — Show public tasker profile (as a different user would see it):
        bio, skills, service areas, hourly rate, "Verified" badge,
        empty reviews section.
04:20 — Coverage report. Show % done. Show what's still outstanding.
04:30 — Stoplight + asks. End.
```

## Risks

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Stripe Connect onboarding requires real AU business details for test | High | High | Use Stripe test data per their docs — they support fully-faked Connect onboarding in test mode |
| ABR API rate limits (1000/day free) | Low | Medium | Cache ABR lookups for 24h locally |
| Didit Flutter SDK has version conflicts with Flutter 3.24 | Low | Medium | If conflict — fall back to webview integration (Didit supports both) |
| Manual KYC review queue takes longer than estimated | Medium | Medium | Cap at "queue exists + approve/reject button works" — full admin UI in S9 |
| User aborts mid-Connect-onboarding — held funds banner gets stuck | Medium | Medium | Reminder cadence (24h / 72h / 7d) covers this; nudges to complete |

## Explicitly NOT in scope

- Full admin KYC dashboard (scaffold only; S9 builds the full UI)
- Tasker availability calendar — DROPPED (per inventory row 42, 43)
- Multi-currency support — multi-country ready, AU-only at MVP
- ABN verification via tax-office side check (just ABR lookup, no deeper validation)
- Hold-out for a different KYC vendor — decision locked at start of sprint

## Day-by-day rough plan

| Day | Mobile | Backend |
| --- | --- | --- |
| Mon 29 (D1) | ADR 005 final, KYC decision locked. Upgrade flow scaffolding. | KYC orchestration scaffolding. Poster→Tasker upgrade endpoint. |
| Tue 30 (D2) | ID upload + selfie UI (per decision path). | ABR API integration. KYC submission endpoint. |
| Wed 1 Jul (D3) | KYC status screen + manual review prompt. ABN entry UI. | KYC state machine + audit log. ABR caching. |
| Thu 2 Jul (D4) | Tasker wizard: bio + skills + service areas. | Connect Express integration start. |
| Fri 3 Jul (D5) | Mid-sprint demo + catch-up. | Mid-sprint demo + catch-up. Connect webhook handler. |
| Mon 6 Jul (D6) | Hourly rate + photo upload + portfolio scaffolding. | Connect onboarding status tracking. Held-funds calculation. |
| Tue 7 Jul (D7) | Held-funds banner + reminder cadence UI. | Connect reminder cadence (cron). |
| Wed 8 Jul (D8) | Public tasker profile view. KYC re-submission flow. | Connect status webhook → mobile push notification. |
| Thu 9 Jul (D9) | Admin scaffold: KYC queue + Connect tracker (basic). Polish. | Polish. AuditLog writes. Bug-fix. |
| Fri 10 Jul (D10) | End-of-sprint demo + CSV update. | Confirm CI green. Tag `sprint-02-end`. |

## Definition of "shippable"

- [ ] All 21 mobile rows done
- [ ] All 7 backend rows done
- [ ] All 2 admin scaffolds done
- [ ] CI green on `main` for 24h
- [ ] ADR 005 (KYC strategy) merged
- [ ] Test ABN lookup works against ABR test endpoint
- [ ] Test Stripe Connect onboarding completes end-to-end in test mode
- [ ] `./scripts/coverage.sh` reports ~25% MVP
- [ ] Sprint 3 detail doc reviewed (already drafted)
- [ ] Demo video uploaded + sent to client

## Expected PRs (~12-15)

- `chore(adrs): 005 KYC strategy`
- `feat(prisma): KYC fields, ServiceArea, Connect fields on User`
- `feat(api/users): poster→tasker upgrade endpoint + AuditLog`
- `feat(api/kyc): KYC orchestration (Didit path) OR (manual path)`
- `feat(api/kyc): KYC webhook with HMAC signature verification`
- `feat(api/users): ABR lookup integration + ABN validation`
- `feat(api/connect): Stripe Connect Express integration`
- `feat(api/connect): Connect webhook handlers + status tracking`
- `feat(api/connect): held-funds calculation per tasker`
- `feat(mobile): poster→tasker upgrade flow + KYC UI`
- `feat(mobile): tasker profile wizard (bio, skills, service areas, rate, photo)`
- `feat(mobile): held-funds banner + reminder cadence rendering`
- `feat(mobile): public tasker profile view`
- `feat(admin): KYC queue scaffold + Connect tracker scaffold`

Each PR closes 1-3 inventory rows.
