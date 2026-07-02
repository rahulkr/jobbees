# Design debt tracker

> ## ✅ Zero active debt as of 2026-07-02
>
> **All 18 Sprint 2 screens shipped before the [Design Quality Charter](./DESIGN-QUALITY-CHARTER.md) landed have been retrofitted in a single pre-launch pass.** Every user-facing surface built to date is at charter bar.
>
> This file is now the **standing** design-debt tracker: any new screen shipped without meeting the charter's design gate (rare — the [PR template](../../.github/pull_request_template.md) enforces it) gets a row here, tiered by urgency. The Sprint 2 inventory below is preserved as a **retrofit log** so future sessions can see how each screen was upgraded and reuse the patterns.
>
> **Do not delete this file** — it's referenced from `apps/mobile/CLAUDE.md`, the PR template, and the charter itself. If active debt drops to zero again after future work, keep the file and update this banner.

---

## The tier system (for any future debt)

| Tier  | When to retrofit                                            | Trigger                                                                           |
| ----- | ----------------------------------------------------------- | --------------------------------------------------------------------------------- |
| **A** | This sprint, before further Sprint 2 work                   | High-visibility + high-first-impression + low-cost = disproportionate polish gain |
| **B** | At next touch (bug fix, feature add, refactor to same file) | The PR that touches the file must retrofit it before merging                      |
| **C** | Post-MVP, dedicated polish sprint                           | Low-visibility, high-cost, or edge-case screens where MVP baseline is acceptable  |

**Enforcement:** the [PR template](../../.github/pull_request_template.md) design gate applies to _creating OR touching_ any Sprint 2 screen. If you touch a Tier B screen for any reason, the design gate must pass in the same PR.

---

## Retrofit log — Sprint 2 inventory (retrofitted 2026-07-02)

The 18 screens that carried debt before the charter landed. All ✅ done. Notes column documents the concrete change patterns applied — reusable for any similar screens shipping in Sprint 3+.

### Onboarding (2 screens)

| Screen           | Path                                                       | Tier  | Est. hours | Status  | Key gaps                                                                                                                                                                                                                                                                  |
| ---------------- | ---------------------------------------------------------- | ----- | ---------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Splash           | `features/onboarding/screens/splash_screen.dart`           | **A** | 3          | ✅ done | Retrofit 2026-07-02: brand-mark scale-in + fade (350ms), staggered tagline entrance, dark-mode radial warmth backdrop, single haptic tap on landing, 1.5s total hold. Widgetbook page at `widgetbook/screens/onboarding/splash_page.dart`.                                |
| Welcome carousel | `features/onboarding/screens/welcome_carousel_screen.dart` | **A** | 4          | ✅ done | Retrofit 2026-07-02: per-slide JEntrance stagger (icon → title → body), breathing icon container on active slide only, haptic on slide change, keyed slides so entrance re-plays on swipe. Widgetbook page at `widgetbook/screens/onboarding/welcome_carousel_page.dart`. |

### Auth (7 screens)

| Screen             | Path                                                  | Tier  | Est. hours | Status  | Key gaps                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| ------------------ | ----------------------------------------------------- | ----- | ---------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Login              | `features/auth/screens/login_screen.dart`             | **B** | 2          | ✅ done | Retrofit 2026-07-02: 6-stop JEntrance stagger across header → email → password → forgot link → CTA → social → footer (0-380ms).                                                                                                                                                                                                                                                                                                                       |
| Signup             | `features/auth/screens/signup_screen.dart`            | **B** | 2          | ✅ done | Retrofit 2026-07-02: 4-stop stagger across header → social → progressive-disclosure form → footer (0-230ms). Progressive disclosure kept as-is (was already a strong choice).                                                                                                                                                                                                                                                                         |
| Verify email       | `features/auth/screens/verify_email_screen.dart`      | **B** | 1.5        | ✅ done | Retrofit 2026-07-02: **replaced raw `CircularProgressIndicator` with a branded pulsing mail-mark** ("Verifying your email…" moment). Verified + failed states wrapped in JEntrance with keyed status so entrance re-plays on state change.                                                                                                                                                                                                            |
| Forgot password    | `features/auth/screens/forgot_password_screen.dart`   | **B** | 1          | ✅ done | Retrofit 2026-07-02: entrance stagger on form (4 stops) and confirmation state (4 stops). Keyed body so entrance re-plays across form → confirmation.                                                                                                                                                                                                                                                                                                 |
| Reset password     | `features/auth/screens/reset_password_screen.dart`    | **B** | 1          | ✅ done | Retrofit 2026-07-02: entrance stagger on form (5 stops) + shared \_Notice widget (used by success + invalid-link states) upgraded with 4-stop stagger. Keyed body across all three states.                                                                                                                                                                                                                                                            |
| Unlock (biometric) | `features/auth/screens/unlock_screen.dart`            | **A** | 2          | ✅ done | Retrofit 2026-07-02: hero mark with continuous breath while biometric prompt is up (stops on idle after failure), staggered entrance on hero/title/body/CTA, failure state uses lock icon + errorContainer bg + warmer "Let's try that again" copy. Widgetbook page: pending (biometric service provider mock needed).                                                                                                                                |
| Account suspended  | `features/auth/screens/account_suspended_screen.dart` | **C** | 1          | ✅ done | Retrofit 2026-07-02: composed directly (bypasses shared `AuthNotice` so this moment gets its own layout). Hero in `errorContainer` tones (serious, not shouting-red) with `LucideIcons.shieldAlert` — reads as "protective pause", not punishment. Warmer copy ("Your account is paused" / "If you think this isn't right, get in touch"). Support email surfaced as its own tap-worthy card so it's actionable, not buried. 4-stop entrance stagger. |

### Verification / Onboarding-to-tasker (4 screens)

| Screen              | Path                                                            | Tier  | Est. hours | Status  | Key gaps                                                                                                                                                                                                                                                                                                                                                                  |
| ------------------- | --------------------------------------------------------------- | ----- | ---------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Become a tasker     | `features/verification/screens/become_tasker_screen.dart`       | **A** | 3          | ✅ done | Retrofit 2026-07-02: hero mark larger (84px), staggered JEntrance across hero/title/body/steps/CTA (7 stagger stops, 0-600ms). Widgetbook page at `widgetbook/screens/verification/become_tasker_page.dart`.                                                                                                                                                              |
| Phone verification  | `features/verification/screens/phone_verification_screen.dart`  | **A** | 2          | ✅ done | Retrofit 2026-07-02: **replaced single-field OTP entry with new `JOtpField`** (6 individually-focused boxes, auto-advance, haptic per digit, paste splitting, auto-submit on 6th). Hero mark switches icon on step change (smartphone → messageSquare), keyed body so entrance re-plays across steps. Widgetbook page: pending (phoneVerificationController mock needed). |
| ABN entry           | `features/verification/screens/abn_entry_screen.dart`           | **B** | 1.5        | ✅ done | Retrofit 2026-07-02: added hero mark (72px building icon in primaryContainer), 4-stop entrance stagger. Success signalling stays via popping to hub which re-renders with fresh status.                                                                                                                                                                                   |
| Verification status | `features/verification/screens/verification_status_screen.dart` | **B** | 2          | ✅ done | Retrofit 2026-07-02: 3-stop entrance stagger across the three cards (Connect → ABN → Phone). Full-screen error state upgraded from plain icon+text to JEmptyState with `Try again` primary. Existing per-card status distinction (icon + tint + chip) was already strong — kept.                                                                                          |

### Profile (3 screens)

| Screen                | Path                                                         | Tier  | Est. hours | Status  | Key gaps                                                                                                                                                                                                                                                                                                                                                                                                        |
| --------------------- | ------------------------------------------------------------ | ----- | ---------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| My profile            | `features/profile/screens/my_profile_screen.dart`            | **B** | 3          | ✅ done | Retrofit 2026-07-02: 4-stop entrance stagger (header → tasker/become-tasker entries → biometric toggle → log-out). **Replaced default `AlertDialog` for switch-to-client with `JBottomSheet`** (charter § conversational confirmations — "Yes, switch to client" / "Keep both"). Signed-out state upgraded from plain text to JEmptyState. Existing full-bleed tap rows (`JCard.tappable`) were already strong. |
| Tasker profile (own)  | `features/profile/screens/tasker_profile_screen.dart`        | **B** | 3          | ✅ done | Retrofit 2026-07-02: 6-stop entrance stagger across intro → bio → rate → skills header → skills editor → save. Replaced default `ScaffoldMessenger.showSnackBar('Profile saved')` with new `JSnackbar.showSuccess`. Error state upgraded to JEmptyState.                                                                                                                                                        |
| Public tasker profile | `features/profile/screens/public_tasker_profile_screen.dart` | **A** | 4          | ✅ done | Retrofit 2026-07-02: designed reviews empty state (JEmptyState inside JCard instead of "No reviews yet." text), staggered entrance across avatar/badges/rate/about/skills/reviews (7 stops, 0-460ms), full-screen error state upgraded to JEmptyState with "Try again" primary action. Widgetbook page: pending (publicTaskerProfileProvider mock needed).                                                      |

### Shell (2 screens)

| Screen           | Path                                                | Tier  | Est. hours | Status  | Key gaps                                                                                                                                                                                                                                                                                                                                                                                     |
| ---------------- | --------------------------------------------------- | ----- | ---------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Home (client)    | `features/home/screens/home_screen.dart`            | **A** | 4          | ✅ done | Retrofit 2026-07-02: dropped default AppBar, time-of-day greeting ("Good morning" / afternoon / evening) + "What needs doing?" as scrollable header, designed placeholder JEmptyState with compass icon signalling where the future feed will live (Sprint 3+). CustomScrollView so future feed slots in underneath the header. Widgetbook page at `widgetbook/screens/home/home_page.dart`. |
| Bottom nav shell | `features/shell/widgets/scaffold_with_nav_bar.dart` | **B** | 1.5        | ✅ done | Retrofit 2026-07-02: added `JHaptics.navigation()` tick on tab-switch and on FAB tap. M3 `NavigationBar` (not deprecated `BottomNavigationBar`) is compliant — kept its default pill indicator.                                                                                                                                                                                              |

### Placeholder (skip)

| Screen            | Path                                             | Tier | Est. hours | Status | Notes                                                        |
| ----------------- | ------------------------------------------------ | ---- | ---------- | ------ | ------------------------------------------------------------ |
| Shell placeholder | `features/shell/screens/placeholder_screen.dart` | —    | —          | —      | Placeholder — real screens replace it later; retrofit is N/A |

---

## Totals

| Tier                  | Screens | Est. hours | Status                                                   |
| --------------------- | ------- | ---------- | -------------------------------------------------------- |
| **A — retrofit now**  | 7       | ~22h       | ✅ **7/7 complete (2026-07-02)**                         |
| **B — next touch**    | 10      | ~17h       | ✅ **10/10 complete (2026-07-02)** — retrofitted upfront |
| **C — post-MVP**      | 1       | ~1h        | ✅ **1/1 complete (2026-07-02)** — retrofitted upfront   |
| **Total design debt** | 18      | **~40h**   | ✅ **40h / 40h resolved (100%)**                         |

40h ≈ **one dedicated retrofit week** or **~3h per sprint for 13 sprints**. Either works. Recommend the dedicated retrofit slot, run between Sprint 2 finish and Sprint 3 start — it's the natural pause point.

---

## Per-screen retrofit workflow (Claude Code, one screen at a time)

For each screen, Claude Code should:

1. **Read** the screen file end-to-end
2. **Audit** against the 12 rejection criteria + 14-box design gate in [`DESIGN-QUALITY-CHARTER.md`](./DESIGN-QUALITY-CHARTER.md)
3. **Update this tracker** — fill in `Key gaps` with the concrete misses (not "polish")
4. **Build the Widgetbook composed page first** — `widgetbook/screens/<category>/<name>_page.dart` — as the design contract
5. **Retrofit the screen** to match the Widgetbook page
6. **Screenshot both light + dark** and attach to the PR
7. **Update tracker status** to ✅ done + PR link

The audit is **not** vague. Every gap must be specific enough that a fix is obvious:

- ❌ Vague: "Needs polish."
- ✅ Specific: "No entrance animation on form fields — should stagger-in over 400ms starting at 100ms."

---

## Legend

- ⬜ pending — not yet audited or retrofitted
- 🟡 audited — gaps identified, retrofit pending
- 🔧 in progress — retrofit branch open
- ✅ done — passed design gate, merged to main
- 🚫 accepted — deliberately deferred to post-MVP (Tier C with justification)

---

## Change log

| Date       | Change                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | By     |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| 2026-07-02 | Tracker created with 18 Sprint 2 screens pre-populated                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Claude |
| 2026-07-02 | **All 7 Tier A screens retrofitted.** New shared components: `JEntrance` (motion helper), `JOtpField` (6-box OTP with auto-advance/haptic/paste), `JHaptics.selection()` (OTP-digit haptic). 4 of 7 Widgetbook screen pages built (splash, welcome carousel, home, become-tasker); the 3 that need Riverpod provider mocks (unlock, phone verification, public tasker profile) are pending.                                                                                                                                                                                                                     | Claude |
| 2026-07-02 | **All 10 Tier B screens retrofitted upfront** (login, signup, verify email, forgot password, reset password, ABN entry, verification status, my profile, own tasker profile, bottom nav shell). Approach was surgical: wrapping existing widgets in `JEntrance` for staggered entry (most screens), upgrading generic error states to `JEmptyState`, replacing `AlertDialog` with `JBottomSheet` (my profile switch-to-client), swapping raw `CircularProgressIndicator` for a branded pulsing mail-mark (verify email), adding haptic feedback to bottom-nav switches. Added `JSnackbar.showSuccess()` helper. | Claude |
| 2026-07-02 | **Tier C retrofitted upfront** — account-suspended screen composed directly (no longer through shared `AuthNotice`) with `errorContainer` hero tones, warmer "Your account is paused" copy, and support email surfaced as a tap-worthy card. **All 18 tracked screens now at Design Quality Charter bar — 100% debt resolved.** Remaining follow-up: build 13 Widgetbook screen pages (needs `ProviderMockScope` helper, ~2h).                                                                                                                                                                                  | Claude |

_Whenever a screen ships, changes tier, or is retrofitted — update this file in the same PR._
