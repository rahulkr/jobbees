# Sprint 1 — Onboarding & Auth

**Dates:** Mon 15 Jun → Fri 26 Jun 2026 (10 working days)
**Theme:** Get a user from "open the app" to "logged in as poster, looking at an empty home screen", then back again via biometric.
**Hours budget:** ~90 (45 mobile, 40 backend, 5 admin)
**Mid-sprint demo:** Fri 19 Jun
**End-of-sprint demo:** Fri 26 Jun

## Goal in one sentence

By Friday 26 Jun, the client can install a build, sign up as a poster or tasker, log in/out, and update their basic profile — running entirely against local Docker (no Azure spend).

## Scope — inventory rows in this sprint

### Mobile (apps/mobile)

| ID | Item | Call | Hrs | Notes |
| --- | --- | --- | --- | --- |
| 1 | Splash screen | IN | 1 | |
| 2 | Email signup (first name, last name, email, mobile, location, user type) | IN | 4 | Single form, validation, hand-off to backend |
| 3 | Google signup | IN | 3 | Flutter `google_sign_in` |
| 4 | Apple signup | IN | 3 | iOS App Store requirement |
| 5 | Email + password login | IN | 2 | |
| 6 | Google login | IN | 1 | Reuses signup integration |
| 7 | Apple login | IN | 1 | Reuses signup integration |
| 9 | Login — biometric (Face ID / Touch ID / fingerprint) | IN | 3 | `local_auth` package |
| 10 | Forgot password / reset flow | IN | 3 | |
| 11 | OTP entry screen | IN | 2 | Used by mobile-verify (taskers) |
| 12 | Email verification (posters) | IN | 2 | Click-through link from email |
| 13 | Phone OTP verification (taskers only) | IN | 3 | Tasker-gated, not poster |
| 14 | Role selection (Poster / Tasker) at signup | IN | 2 | |
| 16 | Permissions priming (location, camera, notifications, photos) | IN | 3 | Per-OS handling |
| 18 | Account suspended/banned screen | IN | 1 | |
| 19 | Force logout (session expired) | IN | 1 | |
| 20 | Account deletion confirmation screen | IN | 2 | |
| 28 | Profile setup (name, photo, default address) | IN | 3 | Poster — minimal |
| 29 | Profile edit | IN | 2 | |
| 33 | Public profile view (limited fields visible to taskers) | IN | 2 | |
| 34 | Verification badges (email, phone, ID) | THIN | 1 | Just rendering, KYC integration in S2 |

**Mobile total: ~45h**

### Backend (apps/api)

| ID | Item | Call | Hrs | Notes |
| --- | --- | --- | --- | --- |
| 228 | User CRUD endpoints | IN | 6 | |
| 229 | OAuth providers (Google, Apple) — server side | IN | 6 | Token validation, profile merge |
| 230 | JWT session + refresh rotation | IN | 4 | |
| 231 | Password hashing + reset tokens | IN | 2 | argon2id |
| 232 | OTP service (Notifyre SMS, SendGrid email) | IN | 5 | |
| 233 | Email verification (posters) | IN | 2 | |
| 234 | Phone OTP verification (taskers only) | IN | 3 | Gated by user_type=tasker |
| 235 | Biometric token exchange | IN | 2 | |
| 236 | Role-based permissions (poster / tasker / admin) | IN | 4 | RolesGuard + Roles decorator |
| 237 | Account suspension / ban | IN | 2 | Schema field + admin-triggered |
| 239 | Session revocation (logout-all) | THIN | 2 | JWT denylist in Redis |
| 242 | User profile + skills + service areas API | IN (partial) | 3 | Skills + service areas defer to S2; just basic profile this sprint |
| 245 | Re-auth gate for change-email/phone | IN | 3 | |

**Backend total: ~44h**

### Admin (apps/admin)

| ID | Item | Call | Hrs | Notes |
| --- | --- | --- | --- | --- |
| 420 | Admin login | IN | 2 | Just the gate — full admin in S9 |
| 424 | Session timeout + re-auth | IN | 2 | |

**Admin total: ~4h**

### Schema additions (packages/prisma)

Already covered in the existing `User` model. Confirm:

- `User.emailVerified`, `User.phoneVerified` ✅
- `User.role` enum ✅
- `User.passwordHash` ✅ (nullable for social-only)
- `User.deletedAt` ✅
- `User.anonymisedAt` ✅

**New tables needed for S1**: `RefreshToken` (or Redis denylist), `EmailVerificationToken`, `PasswordResetToken`. These are NOT in `FUTURE MODELS` yet — add them in the first PR of the sprint.

## Decision gates (must resolve Day 1)

### D1: Auth token storage

**Question:** HttpOnly cookie + CSRF token, or Bearer header in Authorization?

| Option | Pros | Cons |
| --- | --- | --- |
| HttpOnly cookie | Mature web pattern, automatic CSRF defenses available, can't be read by JS | Mobile clients need extra plumbing |
| Bearer header | Mobile-native pattern, simpler dev | Token storage in mobile keychain is your responsibility |

**Recommendation:** Bearer in `Authorization` header for mobile clients (stored in iOS Keychain / Android Keystore), HttpOnly cookie for admin + web. Codified per-surface; one endpoint can issue both. ADR: `docs/adrs/006-auth-tokens.md` to be written in PR #1 of Sprint 1.

### D2: Refresh token storage

**Question:** Redis or Postgres?

**Recommendation:** Postgres `RefreshToken` model with `revokedAt` field for audit trail + queryability. Redis as a fast denylist for active sessions if needed later. Don't over-engineer in S1.

### D3: Password hash

**Recommendation:** argon2id (via `argon2` npm package). Not bcrypt — OWASP recommends argon2id since 2021.

## Definition of done — per feature

A feature is "done" when ALL of these are true:

- [ ] Code merged to `main` via a PR (no direct pushes)
- [ ] CI green: lint, typecheck, test, gitleaks, Semgrep
- [ ] At least 1 unit test exists for the happy path
- [ ] At least 1 test exists for an error / unauthorized case
- [ ] Sensitive endpoints (auth/payment/PII) have `security-review` skill report attached to PR with no CRITICAL findings
- [ ] PR description references the inventory row ID (e.g., "Closes inventory row #2")
- [ ] Feature is visible / testable on the mobile app or admin
- [ ] CSV column 9 updated to `done [sprint-1, PR#nn]`

## Friday client demo script — end of Sprint 1

Record a 3-5 minute screen-cast on your phone running the iOS simulator:

```
00:00 — "Welcome to Sprint 1 wrap. This is JOBBees as of end of week 2."
00:10 — Cold-launch the app. Show splash + welcome screen.
00:30 — Tap "Sign up". Pick "Email". Fill in first name, last name, email,
        mobile, suburb, role = Poster. Tap Continue.
01:00 — Show the email-verify screen. Cut to email inbox showing the
        verify email arrive. Tap the link. Return to app — verified.
01:20 — App lands on poster home screen (empty state — "Post your first
        task!" with a placeholder button).
01:30 — Tap profile icon. Show profile screen with name + avatar
        placeholder. Tap Edit. Update name. Save.
01:50 — Tap Logout. Confirm.
02:00 — On login screen, tap "Sign in with biometric". Face ID prompt.
        Log in instantly.
02:15 — Show forgot-password flow (without completing): enter email →
        "Reset link sent".
02:30 — Switch device — show iOS simulator for tasker signup. Sign up
        as tasker. Show that phone OTP is required (it's a 6-digit code
        from Notifyre — show the test code arriving). Verify.
02:50 — Show role distinction: tasker home looks different (placeholder
        for now — actual content arrives Sprint 2-4).
03:00 — "Here's the coverage report" — run `./scripts/coverage.sh`.
        Show output: features done this sprint, % complete, hours used.
03:20 — Stoplight: green (auth, signup, login, biometric); yellow (oauth
        Google/Apple — works but Apple needs paid developer account
        finalised); red (none).
03:40 — "Next sprint starts Monday: KYC + tasker upgrade + Stripe Connect
        onboarding. We need your KYC vendor decision by Friday 26 Jun
        EOD." End.
```

## Risks specific to Sprint 1

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Apple Developer Program not set up — can't test Apple sign-in on real device | Medium | Medium | Test on simulator only; defer real-device validation to Sprint 11; enrol now ($99/yr) so it's ready |
| Notifyre alpha sender ID not approved yet | Medium | Medium | Apply for `JOBBEES` alpha sender Day 1; use test mode in dev; doesn't block end-of-S1 demo |
| Email deliverability problems (SendGrid) | Low | Medium | Use SendGrid test sender for dev; warm-up domain in Sprint 10 before launch |
| Biometric setup needs platform-specific channel code | Medium | Low | `local_auth` Flutter package handles 90%; expect a few hours of native channel debugging |
| Google + Apple OAuth client IDs missing | High | High | Get OAuth client IDs first day; documented in `.env.example` |

## Things that are explicitly NOT in this sprint

These go to later sprints — do NOT scope-creep them in:

- KYC document upload + ID verification — **Sprint 2**
- ABN entry + ABR lookup — **Sprint 2**
- Stripe Connect onboarding — **Sprint 2**
- Full tasker profile (skills, service areas, hourly rate, portfolio) — **Sprint 2**
- Poster→tasker upgrade flow — **Sprint 2**
- Task posting — **Sprint 3**
- Discovery / bidding — **Sprint 4**
- Anything payment-related — **Sprint 5**
- Magic link login — DROPPED (per inventory row 8)
- Welcome tour / coach marks — DROPPED (per inventory row 17)
- Address book — Sprint 2 thin
- 2FA for users — POST (deferred)
- Linked accounts unlink — Sprint 2 thin

If something on this list comes up in conversation, response is "noted, queued for Sprint N" — not "let me add it".

## Day-by-day rough plan (you'll adjust)

| Day | Mobile | Backend |
| --- | --- | --- |
| Mon 15 (D1) | Splash + signup form scaffolding. ADRs 006 (auth tokens) decided. | Auth module bootstrap. JWT + refresh rotation. `RefreshToken` Prisma model + migration. |
| Tue 16 (D2) | Signup form validation + submit. | User CRUD. Password hashing (argon2id). Reset token flow. |
| Wed 17 (D3) | Email/password login. Logout. | OTP service (Notifyre + SendGrid stubs). Email verification flow. |
| Thu 18 (D4) | Google + Apple signup. OAuth UX. | OAuth providers server-side. Token exchange + profile merge. |
| Fri 19 (D5) | Mid-sprint demo prep + recording. | Mid-sprint demo prep. Catch up on debt. |
| Mon 22 (D6) | Biometric login (local_auth). Forgot-password flow UI. | Role-based permissions (RolesGuard). |
| Tue 23 (D7) | OTP entry screen. Phone OTP (tasker). | Phone OTP backend. Biometric token exchange. |
| Wed 24 (D8) | Permissions priming. Poster profile setup + edit. | User profile API. Re-auth gate for email/phone change. |
| Thu 25 (D9) | Public profile view. Verification badges (rendering only). Suspended / force-logout / deletion screens. | Account suspension/ban. Session revocation. Admin login (basic). |
| Fri 26 (D10) | End-of-sprint demo recording. Bug bash. CSV update. | Same. Confirm CI green. Tag `sprint-01`. |

## Definition of "shippable" at end of Sprint 1

- [ ] All 21 mobile inventory rows in scope are done (mark in CSV)
- [ ] All 13 backend inventory rows in scope are done (mark in CSV)
- [ ] All 2 admin inventory rows in scope are done (mark in CSV)
- [ ] CI on `main` is green for last 24 hours
- [ ] iOS simulator build runs the entire demo script start-to-finish without crashing
- [ ] Android emulator build runs the entire demo script start-to-finish without crashing
- [ ] `./scripts/coverage.sh` reports the 36 features as done out of ~310 total IN/IN★ (~12% MVP)
- [ ] ADRs 005 (KYC) and 006 (auth tokens) merged
- [ ] Sprint 2 detail doc (`sprint-02-kyc-and-tasker.md`) drafted and committed
- [ ] Friday demo video uploaded + sent to client

## Sprint-1 PRs (expected ~10-12)

Estimated PR slicing (small PRs, < 400 LOC each per PR template):

1. `chore(adrs): 006 auth token storage decision`
2. `feat(prisma): RefreshToken, EmailVerificationToken, PasswordResetToken models`
3. `feat(api/auth): JWT issue + refresh rotation`
4. `feat(api/auth): argon2id password hashing + reset token flow`
5. `feat(api/auth): OAuth Google + Apple server-side`
6. `feat(api/users): user CRUD + profile + re-auth gate`
7. `feat(api/auth): role-based permissions guard`
8. `feat(api/auth): OTP service (Notifyre SMS + SendGrid email)`
9. `feat(api/auth): phone OTP verification + biometric token exchange`
10. `feat(api/auth): session revocation + account suspend/ban`
11. `feat(mobile): splash + signup + login + role select`
12. `feat(mobile): OAuth providers + biometric + OTP entry`
13. `feat(mobile): poster profile + permissions priming + suspended/deletion screens`
14. `feat(admin): admin login + session timeout`

Each PR closes 1-3 inventory rows.

## After end-of-sprint demo

Same Friday afternoon, before the weekend:

1. Update `inventory/JOBBees_Feature_Inventory.csv` column 9 for every done row → `done [sprint-1, PR#nn]`
2. Run `./scripts/coverage.sh > /tmp/coverage-s1.txt`
3. Run `./scripts/coverage.sh --by-section > /tmp/coverage-s1-by-section.txt`
4. Run `./scripts/coverage.sh --remaining > /tmp/coverage-remaining.txt`
5. Email client with: demo video link + coverage summary + Sprint 2 decision asks (KYC vendor)
6. Commit `docs/sprints/sprint-02-kyc-and-tasker.md` (drafted during Sprint 1's last few days)
7. Tag the merge commit on `main` as `sprint-01-end`
8. Close the sprint in any project tracker (if you're using one)
9. Two-day weekend. Don't open the laptop.
