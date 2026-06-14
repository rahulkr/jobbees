# Sprint 2 — Mobile Auth + Onboarding + Tasker upgrade + Stripe Connect + ABN

> **Note:** Per the 2026-06-12 plan restructure, Sprint 2 became the **first user-visible sprint**. Mobile auth + onboarding (originally in Sprint 1) move here, integrating against the now-stable Sprint 1 backend. License verification (mobile upload + backend module + offer-time guard + expiry cron + admin review queue scaffold) **deferred to Sprint 4**, where it lives natively with the offering code.

**Dates:** Mon 6 Jul → Fri 17 Jul 2026 (10 working days)
**Theme:** First "click through the app" sprint. Mobile lands and integrates against the real backend from Sprint 1. By Friday a user can install the app, sign up, log in, become a tasker, complete Stripe Connect, and verify their ABN.
**Hours budget:** ~95 (60 mobile, 30 backend, 5 admin scaffolding)
**Mid-sprint demo:** Fri 10 Jul
**End-of-sprint demo:** Fri 17 Jul

## Goal in one sentence

By Friday 17 Jul, a user can cold-launch the app, see the welcome carousel, sign up (email/Google/Apple), verify OTP (against MockOtpService), pick a role, land on client home, tap "Become a tasker", complete Stripe Connect onboarding (Stripe handles identity KYC), verify their ABN — all against the real Sprint 1 backend, running entirely on local Docker.

## Verification model (per ADR 005)

We are NOT using an identity vendor (Didit / Stripe Identity / similar). Three independent layers:

1. **Stripe Connect Express KYC** — Stripe handles end-to-end during their onboarding flow (this sprint)
2. **ABN verification** — JOBBees calls free ABR API (checksum + business name) (this sprint)
3. **Professional license verification** (per category, only for licensed trades) — **deferred to Sprint 4 with offering**

Most categories (cleaning, gardening, moving, handyman, IT, tutoring, Ikea assembly) require NO license. Licensed trades (electrical, plumbing, gas, asbestos, refrigerated AC, pest control, builder>$5K NSW) need a category-specific license — which lands in Sprint 4 alongside the offering code that gates on it.

## Scope — inventory rows

### Mobile (apps/mobile) — auth + onboarding + tasker upgrade

| ID  | Item                                                                     | Call | Hrs | Notes                                                                                                                                            |
| --- | ------------------------------------------------------------------------ | ---- | --- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | Splash screen                                                            | IN   | 1   |                                                                                                                                                  |
| 527 | **Welcome carousel (3 screens — what JOBBees does)**                     | IN   | 4   | First-launch only, skippable, persists "seen" flag locally                                                                                       |
| 2   | Email signup (first name, last name, email, mobile, location, user type) | IN   | 4   | Single form with validation; hits Sprint 1 `/auth/signup`                                                                                        |
| 3   | Google signup                                                            | IN   | 3   | Flutter `google_sign_in` package                                                                                                                 |
| 4   | Apple signup                                                             | IN   | 3   | iOS App Store requirement (if you offer ANY social sign-in, you must offer Apple)                                                                |
| 5   | Email + password login                                                   | IN   | 2   | Hits Sprint 1 `/auth/login`                                                                                                                      |
| 6   | Google login                                                             | IN   | 1   | Reuses signup integration                                                                                                                        |
| 7   | Apple login                                                              | IN   | 1   | Reuses signup integration                                                                                                                        |
| 9   | Login — biometric (Face ID / Touch ID / fingerprint)                     | IN   | 3   | `local_auth` package + biometric token exchange against Sprint 1 endpoint                                                                        |
| 10  | Forgot password / reset flow                                             | IN   | 3   | Email reset link from Sprint 1 backend                                                                                                           |
| 11  | OTP entry screen                                                         | IN   | 2   | Used by phone verify; autofills via Smart Auth (iOS) / SMS Retriever (Android)                                                                   |
| 12  | Email verification (clients)                                             | IN   | 2   | Click-through link from email                                                                                                                    |
| 13  | Phone OTP verification (taskers only)                                    | IN   | 3   | Tasker-gated; uses MockOtpService (`000000`) until Sprint 5 OTP swap                                                                             |
| 14  | Role selection (Client / Tasker / Decide later) at signup                | IN   | 2   |                                                                                                                                                  |
| 16  | Permissions priming (location, camera, notifications, photos)            | IN   | 3   | Per-OS handling; show value prop before OS prompt                                                                                                |
| 18  | Account suspended/banned screen                                          | IN   | 1   |                                                                                                                                                  |
| 19  | Force logout (session expired)                                           | IN   | 1   |                                                                                                                                                  |
| 20  | Account deletion confirmation screen                                     | IN   | 2   |                                                                                                                                                  |
| 28  | Profile setup (name, photo, default address)                             | IN   | 3   | Client — minimal                                                                                                                                 |
| 29  | Profile edit                                                             | IN   | 2   |                                                                                                                                                  |
| 33  | Public profile view (limited fields visible to taskers)                  | IN   | 2   |                                                                                                                                                  |
| 34  | Verification badges (email, phone, Stripe Connect)                       | THIN | 1   | Just rendering; license badges come in Sprint 4                                                                                                  |
| 15  | Client → Tasker upgrade flow (one-way only)                              | IN   | 4   | Triggers Stripe Connect + ABN entry                                                                                                              |
| 24  | ABN entry + ABR lookup UI                                                | IN   | 3   | Tasker-only; checksum + business name match via ABR API                                                                                          |
| 25  | Verification status screen (Connect / ABN)                               | IN   | 2   | Replaces old "KYC status screen"; license tab comes in S4                                                                                        |
| 35  | Tasker profile setup wizard (multi-step)                                 | IN   | 5   |                                                                                                                                                  |
| 36  | Bio / about me                                                           | IN   | 1   |                                                                                                                                                  |
| 37  | Skills selection (categories + tags)                                     | IN   | 3   | Flags `requiresLicense` + `licenseRequiredOverCents` categories visually with "License required in S4" chip — sets expectations without blocking |
| 38  | Service areas (suburb / radius picker)                                   | IN   | 3   |                                                                                                                                                  |
| 39  | Hourly rate / minimum job fee                                            | IN   | 1   |                                                                                                                                                  |
| 40  | Profile photo + cover image upload                                       | IN   | 2   |                                                                                                                                                  |
| 44  | Stripe Connect onboarding entry                                          | IN   | 2   | Stripe handles all identity KYC end-to-end                                                                                                       |
| 45  | Held-funds banner                                                        | IN   | 2   | Persistent until Connect complete                                                                                                                |
| 46  | Connect reminder cadence — mobile rendering                              | IN   | 2   | 24h / 72h / 7d                                                                                                                                   |
| 47  | Public tasker profile (visible to clients)                               | IN   | 3   | Shows Stripe Connect verified badge; license badges come in S4                                                                                   |
| 48  | Portfolio / previous work photos                                         | THIN | 2   | Upload + render only                                                                                                                             |
| 49  | Reviews received display                                                 | IN   | 2   | Empty state for now                                                                                                                              |

**Mobile total: ~60h**

REMOVED from earlier draft (deferred to Sprint 4 with offering):

- ~~Row 41: License upload~~ — deferred to S4
- ~~Row 531: Licensed-trade category selector~~ — deferred to S4 (skills picker in S2 just flags categories visually)

### Backend (apps/api) — tasker upgrade + Stripe Connect + ABN

| ID  | Item                                    | Call | Hrs | Notes                                                                                                 |
| --- | --------------------------------------- | ---- | --- | ----------------------------------------------------------------------------------------------------- |
| 241 | ABN + ABR lookup integration            | IN   | 3   | https://abr.business.gov.au/ ; 24h local cache                                                        |
| 244 | Client→Tasker upgrade backend (one-way) | IN   | 3   | State change, triggers Connect onboarding init                                                        |
| 292 | Stripe Connect Express integration      | IN   | 12  | Stripe handles identity KYC end-to-end                                                                |
| 293 | Connect webhook handlers                | IN   | 6   | `account.updated`, `account.application.authorized`, etc. — HMAC signature verified before processing |
| 294 | Connect onboarding status tracking      | IN   | 4   | Pending → restricted → complete state transitions; mirrors to User.kycStatus                          |
| 295 | Held-funds calculation per tasker       | IN   | 3   | Sum of captured-but-not-released amounts                                                              |

**Backend total: ~31h**

REMOVED from earlier draft (deferred to Sprint 4):

- ~~Row 240: License verification module~~ — deferred to S4
- ~~Row 532: Offer-time license guard~~ — deferred to S4 (offering code's natural home)
- ~~Row 533: License expiry cron~~ — deferred to S4

### Admin scaffolding (apps/admin)

| ID  | Item                                     | Call | Hrs | Notes                                                              |
| --- | ---------------------------------------- | ---- | --- | ------------------------------------------------------------------ |
| 431 | Stripe Connect status mirror (read-only) | THIN | 2   | Display Connect verification state per tasker; full admin UI in S9 |
| 432 | Connect onboarding tracker (scaffold)    | IN   | 3   | List view of Connect statuses                                      |

**Admin total: ~5h**

REMOVED: ~~Row 534 (License review queue scaffold)~~ — deferred to Sprint 4 alongside the License module.

### Schema additions

- Add to User: `stripeConnectAccountId String?`, `connectStatus ConnectStatus @default(NOT_STARTED)`, `connectOnboardedAt DateTime?`
- Add to User: `abn String?`, `abnVerifiedAt DateTime?`, `abrBusinessName String?`, `noAbnReason String?`
- New `ServiceArea` model (from FUTURE MODELS): `userId`, `suburb`, `postcode`, `radiusKm Int @default(15)`, composite `@@unique([userId, suburb])`
- New `Category` seeds: full category catalog including the `requiresLicense Boolean @default(false)` + `licenseRequiredOverCents Int?` fields per ADR 005. Sprint 2 seeds the data; Sprint 4 wires up the offer-time guard that consumes it. Builder seeded with `licenseRequiredOverCents = 500000`, all unconditional licensed trades seeded with `requiresLicense = true`.
- New shared TypeScript constant **`packages/types/src/licenses.ts`** — `ALLOWED_LICENSE_TYPES` per ADR 005 "Allowed license types per category" section. 13 license type slugs across 8 categories (Electrical, Plumbing, Drainage, Gas fitting, Asbestos, Refrigerated AC, Pest control, Builder). Plus 8-value `ISSUING_STATES` const (`NSW`/`VIC`/`QLD`/`WA`/`SA`/`TAS`/`ACT`/`NT`). Mobile dropdowns + backend offer-time guard (S4) + admin License Review Queue (S4 scaffold, S9 full) all import from this single file. Add the constant in Sprint 2 even though License upload UI lands in Sprint 4 — having it landed early lets the Category seeds reference it.

REMOVED from earlier draft (deferred to Sprint 4 with offering):

- ~~`License` model~~ — added in Sprint 4
- ~~`LicenseStatus` enum~~ — added in Sprint 4

## Decisions — already locked (no Day 1 gate)

Per **ADR 005**: We're NOT using an identity-vendor KYC. Stripe Connect Express handles identity verification end-to-end. JOBBees does:

- **Stripe Connect onboarding** — Stripe webview, Stripe handles legal KYC
- **ABN verification** — free ABR API call
- **License verification** (manual, per licensed category) — Sprint 4

No Didit / Stripe Identity / 3rd-party identity vendor. Simpler IT audit, fewer subprocessors.

## Definition of done

Same as Sprint 1, plus:

- [ ] Mobile app cold-launches to splash → welcome carousel → signup screen
- [ ] Signup, login, OTP, refresh all hit real Sprint 1 backend (no mocks)
- [ ] Biometric re-login works on iOS simulator + Android emulator
- [ ] Stripe Connect webhook signature verified BEFORE any DB write (skill §H5)
- [ ] ABR API lookups cached 24h (rate-limit protection)
- [ ] AuditLog write on every Connect state transition
- [ ] All test users use `@example.com` and `+61400000000` test format (no realistic PII per CLAUDE.md)
- [ ] No raw Stripe `account.update` payload logged (it can contain PII)
- [ ] Mobile app uses theme tokens from `apps/mobile/lib/theme/` everywhere — no raw `Color(0xFF...)`
- [ ] All 4 screen states implemented per `apps/mobile/CLAUDE.md` hard rule 3 (loading, error, empty, content)

## Friday demo (Fri 17 Jul) — first "click through the app" demo

5-6 minute screencast:

```
00:00 — "Sprint 2 wrap. First user-visible demo. From here on, every
        Friday demo is 'open the app and click through.'"

00:15 — Cold-launch on iOS simulator. Splash → welcome carousel (3 screens)
        → "Get started".

00:40 — Signup screen. Pick "Sign up with email". Fill form (Rahul Test,
        rahul@example.com, +61400000000, Sydney, Client). Submit.

01:00 — OTP entry screen. Enter `000000`. Verify. Banner: "Phone verified."
        (Server log shows MockOtpService used; AuditLog row created.)

01:20 — Email verification: tap simulated link. Land on role select.
        Pick "Client". Land on client home (empty state — "No jobs yet.
        Posting comes in Sprint 3.").

01:45 — Hard close app. Reopen. Biometric prompt fires. Touch ID
        (simulated). Logged back in.

02:10 — Settings → "Become a tasker." One-way confirmation dialog.
        Continue.

02:30 — Stripe Connect webview launches. Show the Stripe-hosted onboarding
        form (Stripe handles ALL identity KYC — name, DOB, address,
        gov ID, selfie, bank). Complete with test data.

03:10 — Return to app → Connect webhook fires → status updates to
        "Pending Review" then (a few seconds later) "Approved" (test mode
        is instant). Held-funds banner updates.

03:30 — ABN entry screen. Enter test ABN. ABR API lookup populates
        business name. Submit.

03:50 — Tasker profile wizard: bio, skills (multi-select chips with
        "License required in Sprint 4" badge on Plumbing / Electrical etc.),
        service areas (suburb + 15km), hourly rate, profile photo.

04:30 — Public tasker profile renders: Stripe Connect verified badge,
        ABN verified badge, empty reviews. (License badges arrive in S4.)

04:50 — Switch to admin: scaffold-level Connect onboarding tracker shows
        the new tasker in the list with "Approved" status.

05:10 — Coverage report. Stoplight + asks. End.

05:30 — "Sprint 3 starts Monday: job posting + AI extraction + guest mode.
        Sprint 4 lands offering + license verification + Verified Plumber
        badges."
```

## Risks

| Risk                                                                         | Likelihood | Impact | Mitigation                                                                                                                                                  |
| ---------------------------------------------------------------------------- | ---------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Stripe Connect application not approved by Mon 6 Jul                         | Medium     | High   | Started Mon 22 Jun (Sprint 1 D1); 5-10 business day lead time means latest approval Mon 6 Jul. If late, demo a webview placeholder + complete ABN flow only |
| Stripe Connect onboarding requires real AU business details                  | Medium     | High   | Use Stripe test data per their docs — they support fully-faked Connect onboarding in test mode                                                              |
| ABR API rate limits (1000/day free tier)                                     | Low        | Medium | 24h local cache; backend rate-limits per user                                                                                                               |
| Apple Developer Program not approved → can't test Apple Sign-in on simulator | Low        | Medium | iOS simulator + Apple Sign-in works without paid Developer Program for development. Production requires it but that's Sprint 11                             |
| Mobile dev velocity slower than estimated for first sprint                   | Medium     | Medium | Sprint 1 left ~14h unused (originally 94h budget, backend trimmed to 80). That headroom rolls into Sprint 2                                                 |
| Apple Sign-in returns name only once and you forgot to capture it            | Medium     | Medium | Capture firstName + lastName on FIRST Apple Sign-In response and persist immediately to backend                                                             |
| Social-auth users have no password — login fallback misses this              | Low        | High   | Backend allows password-less signup (`User.passwordHash` nullable per Sprint 1 schema); login screen treats "password not set" as social-only               |

## Explicitly NOT in scope (deferred to S4 with offering)

- License upload UI (mobile row 41)
- Licensed-trade category selector (mobile row 531)
- License module backend (row 240)
- Offer-time license guard (row 532)
- License expiry cron (row 533)
- Admin License Review Queue scaffold (row 534)

S2 just flags `requiresLicense` + `licenseRequiredOverCents` categories visually so taskers know what's coming. The offer-time gating + upload + review queue land natively in S4.

## Day-by-day rough plan

| Day          | Mobile                                                                                                                          | Backend                                                             |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| Mon 6 (D1)   | Project scaffold (Flutter app + Riverpod + go_router + dio). Splash + welcome carousel.                                         | Stripe Connect Express scaffold. ABR API client + 24h cache.        |
| Tue 7 (D2)   | Email signup screen → real `/auth/signup`. OTP entry → real `/auth/otp/verify`.                                                 | Stripe Connect onboarding init endpoint. Connect webhook handler.   |
| Wed 8 (D3)   | Google + Apple signup. Role select. Forgot password.                                                                            | Connect onboarding status tracking. Client→Tasker upgrade endpoint. |
| Thu 9 (D4)   | Login + biometric re-login. Email verify. Permissions priming.                                                                  | Held-funds calculation. ABN validation + ABR lookup endpoint.       |
| Fri 10 (D5)  | **Mid-sprint demo + catch-up.**                                                                                                 | Mid-sprint demo + catch-up. AuditLog wiring complete.               |
| Mon 13 (D6)  | Account-suspended / force-logout / deletion screens. Profile setup + edit.                                                      | Connect reminder cadence (24h / 72h / 7d cron).                     |
| Tue 14 (D7)  | Client→Tasker upgrade entry. ABN entry UI + ABR result screen.                                                                  | Connect status webhook → push notification.                         |
| Wed 15 (D8)  | Tasker wizard: bio + skills + service areas. Stripe Connect webview entry.                                                      | Admin Connect tracker endpoint.                                     |
| Thu 16 (D9)  | Tasker wizard: hourly rate + photo + portfolio scaffold. Held-funds banner + reminder cadence rendering. Public tasker profile. | Polish. AuditLog write coverage check.                              |
| Fri 17 (D10) | End-of-sprint demo + CSV update.                                                                                                | Confirm CI green. Tag `sprint-02-end`.                              |

## Definition of "shippable"

- [ ] All ~37 mobile rows done
- [ ] All 6 backend rows done
- [ ] All 2 admin scaffolds done
- [ ] CI green on `main` for 24h
- [ ] Test ABN lookup works against ABR test endpoint
- [ ] Test Stripe Connect onboarding completes end-to-end in test mode
- [ ] `./scripts/coverage.sh` reports ~22% MVP
- [ ] Sprint 3 detail doc reviewed (already drafted)
- [ ] Sprint 4 detail doc updated to absorb License module + offer-time guard + license review queue
- [ ] Demo video uploaded + sent to client

## Expected PRs (~14-18)

- `feat(prisma): User.stripeConnect*, User.abn*, ServiceArea model, Category seeds with requiresLicense + licenseRequiredOverCents (Builder $5K)`
- `feat(api/users): client→tasker upgrade endpoint + AuditLog`
- `feat(api/users): ABR lookup integration + ABN validation`
- `feat(api/connect): Stripe Connect Express integration`
- `feat(api/connect): Connect webhook handlers + signature verification + status tracking`
- `feat(api/connect): held-funds calculation per tasker`
- `feat(api/connect): Connect reminder cadence cron`
- `feat(mobile): scaffold + splash + welcome carousel`
- `feat(mobile): email/Google/Apple signup + login + biometric`
- `feat(mobile): OTP + email verify + role select + permissions priming`
- `feat(mobile): client profile + suspend/banned/deletion screens`
- `feat(mobile): client→tasker upgrade flow + ABN entry UI`
- `feat(mobile): tasker profile wizard (bio, skills, service areas, rate, photo)`
- `feat(mobile): Stripe Connect webview + held-funds banner + reminder cadence`
- `feat(mobile): public tasker profile view`

- `feat(admin): Connect tracker scaffold + Connect status mirror`

Each PR closes 1-3 inventory rows.
