# Sprint 11 — TestFlight + Play Store internal + bug-fix + launch hardening

**Dates:** Mon 9 Nov → Fri 20 Nov 2026 (10 working days)
**Theme:** First time real human hands hold the app on real devices. Whatever breaks, fix it. Legal / store listings / SEO go in. App is ready to face actual paying users.
**Hours budget:** ~154 (23 mobile polish, 10 backend polish, 15 bug-fix budget, 15 launch hardening, 6 pre-launch pen test, 60 full SEO bundle incl. SEO-18 + SEO-19 audit adds, 10 Flutter Web final polish, web a11y audit bundled with SEO) — 3-week sprint; soft launch Jan 8 2027.
**Mid-sprint demo:** Fri 13 Nov
**End-of-sprint demo:** Fri 20 Nov

## Goal in one sentence

By Friday 13 Nov, the client installs JOBBees on their iPhone via TestFlight + on an Android phone via Play Store internal track, runs the entire happy path (signup → KYC → post job → offer → accept → message → pay → complete → review → tax invoice), reports bugs, you fix them.

## Scope

### TestFlight + Play Store

| Item                                                          | Hrs | Notes        |
| ------------------------------------------------------------- | --- | ------------ |
| Apple Developer Program — confirm enrolled, agreements signed | 1   | $99/yr       |
| iOS signing certificates + provisioning profiles              | 2   |              |
| App Store Connect listing + metadata                          | 3   |              |
| TestFlight internal testers added (you + client + 2-3)        | 1   |              |
| First TestFlight build uploaded + processed                   | 2   |              |
| Google Play Developer Account enrolled, agreements signed     | 1   | $25 one-time |
| Android signing key (upload + app signing)                    | 2   |              |
| Google Play Console listing + metadata                        | 3   |              |
| Play Store internal track set up + testers added              | 1   |              |
| First AAB uploaded + processed                                | 2   |              |

### Mobile polish

| ID  | Item                                                                                                                                                                                                                                                                                                                                                                            | Call | Hrs | Notes                                                                                                                                                                                 |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---- | --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 70  | Re-post / clone job                                                                                                                                                                                                                                                                                                                                                             | THIN | 1   |                                                                                                                                                                                       |
| 84  | Job search bar — polish                                                                                                                                                                                                                                                                                                                                                         | THIN | 1   |                                                                                                                                                                                       |
| 153 | Blind review with timeout-reveal — polish                                                                                                                                                                                                                                                                                                                                       | THIN | 1   |                                                                                                                                                                                       |
| 156 | Edit / delete own review (within window)                                                                                                                                                                                                                                                                                                                                        | THIN | 1   |                                                                                                                                                                                       |
| 167 | Dispute history per user                                                                                                                                                                                                                                                                                                                                                        | THIN | 1   |                                                                                                                                                                                       |
| 177 | Notification history / replay                                                                                                                                                                                                                                                                                                                                                   | THIN | 2   |                                                                                                                                                                                       |
| 183 | Linked accounts view + unlink                                                                                                                                                                                                                                                                                                                                                   | THIN | 2   |                                                                                                                                                                                       |
| 184 | Notification preferences — polish                                                                                                                                                                                                                                                                                                                                               | THIN | 2   |                                                                                                                                                                                       |
| 189 | Logout from all devices                                                                                                                                                                                                                                                                                                                                                         | THIN | 1   |                                                                                                                                                                                       |
| 195 | Report a bug / feedback form                                                                                                                                                                                                                                                                                                                                                    | THIN | 2   |                                                                                                                                                                                       |
| 197 | Send logs to support                                                                                                                                                                                                                                                                                                                                                            | THIN | 2   |                                                                                                                                                                                       |
| 209 | App update prompt (soft / force)                                                                                                                                                                                                                                                                                                                                                | IN   | 2   |                                                                                                                                                                                       |
| 210 | Maintenance mode screen                                                                                                                                                                                                                                                                                                                                                         | THIN | 1   |                                                                                                                                                                                       |
| 211 | Offline indicator                                                                                                                                                                                                                                                                                                                                                               | THIN | 2   |                                                                                                                                                                                       |
| 212 | Offline draft persistence (jobs only)                                                                                                                                                                                                                                                                                                                                           | THIN | 3   |                                                                                                                                                                                       |
| 213 | Empty states — **expanded scope: act as contextual tutorials**                                                                                                                                                                                                                                                                                                                  | IN   | 5   | Was 3; +2 for instructive copy + illustrations on every empty state                                                                                                                   |
| 214 | Error boundary screens                                                                                                                                                                                                                                                                                                                                                          | IN   | 2   |                                                                                                                                                                                       |
| 215 | Network retry / loader UX                                                                                                                                                                                                                                                                                                                                                       | IN   | 2   |                                                                                                                                                                                       |
| 216 | Crash reporting (Sentry SDK) — **final polish only** (SDK wired in S2 per scope reconciliation #20)                                                                                                                                                                                                                                                                             | THIN | 1   | Was 2h. Foundations in S2; this is the production-DSN swap, source-map upload verification on the TestFlight build, alert-rule sanity check.                                          |
| 217 | Analytics events (PostHog SDK) — **final polish only** (SDK wired in S2 per scope reconciliation #9)                                                                                                                                                                                                                                                                            | THIN | 1   | Was 3h. Foundations in S2 (instrumented as we built); this is the funnel-dashboard review + event-naming audit.                                                                       |
| 218 | **Mobile a11y full audit pass (WCAG 2.1 AA)** — foundations laid in S2 (per scope reconciliation #23). This sprint runs the audit: TalkBack pass (Android), VoiceOver pass (iOS), focus-order check on every screen, contrast verified against `apps/mobile/lib/theme/`, semantic widget audit, `flutter test --tags accessibility`. Document findings + fix the critical ones. | IN   | 4   | Was THIN 4h. Same hour budget but now an actual audit with a deliverable (audit report in `docs/audit/mobile-a11y-2026-q4.md`). Closes gap register #23.                              |
| 220 | Background tasks (location during active job)                                                                                                                                                                                                                                                                                                                                   | IN   | 3   |                                                                                                                                                                                       |
| 221 | App lifecycle handling (background / foreground)                                                                                                                                                                                                                                                                                                                                | IN   | 2   |                                                                                                                                                                                       |
| 222 | Biometric prompt on payment / sensitive action                                                                                                                                                                                                                                                                                                                                  | THIN | 2   |                                                                                                                                                                                       |
| 223 | Push token rotation — **final polish only** (full rotation handling in S8 per scope reconciliation #21)                                                                                                                                                                                                                                                                         | THIN | 0.5 | Was 2h. Implementation in S8; this is just a TestFlight smoke test that uninstall-reinstall properly rotates the token.                                                               |
| 224 | Universal link verification setup — **final polish only** (foundations in S2 per scope reconciliation #19)                                                                                                                                                                                                                                                                      | THIN | 1   | Was 2h. apple-app-site-association + assetlinks.json hosted in S2; this is the Apple Validator + `adb shell pm verify-app-links` final pass on the TestFlight + Play internal builds. |
| 225 | App icon, splash, launch animation                                                                                                                                                                                                                                                                                                                                              | IN   | 2   |                                                                                                                                                                                       |
| 226 | App Store / Play Store listings + screenshots                                                                                                                                                                                                                                                                                                                                   | IN   | 4   |                                                                                                                                                                                       |
| 227 | App Tracking Transparency prompt (iOS)                                                                                                                                                                                                                                                                                                                                          | IN   | 1   |                                                                                                                                                                                       |
| 196 | **App version / build info** (per Estimation v1.2 audit) — Settings screen shows app version + build number. Required for CS to identify which version a user is on when supporting them.                                                                                                                                                                                       | IN   | 1   | Simple Settings row.                                                                                                                                                                  |
| 528 | **Contextual tooltips on first use (5-6 key moments)**                                                                                                                                                                                                                                                                                                                          | IN   | 5   | New: first-time-only tooltips on offer placement, accept offer, held funds, completion proof, AI-matched badge. Track "seen" via local storage. Auto-dismiss 4s.                      |
| 529 | **"How it works" static help page**                                                                                                                                                                                                                                                                                                                                             | IN   | 2   | New: single screen explaining post / offer / payment / become-tasker. Linked from empty states + Help menu.                                                                           |

### Legal pages (mobile)

| ID  | Item                   | Call | Hrs |
| --- | ---------------------- | ---- | --- |
| 198 | Terms of Service       | IN   | 1   |
| 199 | Privacy Policy         | IN   | 1   |
| 200 | Community guidelines   | IN   | 1   |
| 201 | RCTI agreement         | IN   | 1   |
| 202 | Cancellation policy    | IN   | 1   |
| 203 | Open source licenses   | IN   | 1   |
| 204 | About page             | IN   | 1   |
| 205 | Contact / company info | IN   | 1   |

### Public web (apps/web) — full SEO bundle (added per founder direction 14 Jun 2026)

The thin SEO row set is replaced by the full Next.js SEO bundle, paired with the Flutter Web app that launched in Sprint 2. Sprint 3 already shipped the public job detail page + Schema.org + OG cards per job; this sprint completes the rest of the bundle.

| ID     | Item                                                                                                                                                                                                                                                                                   | Call | Hrs | Notes                                                                                                                    |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---- | --- | ------------------------------------------------------------------------------------------------------------------------ |
| 516    | **Public marketing landing page (full version, not THIN)** — hero, value props for client + tasker sides, "How it works" embedded, social proof carousel, Sydney suburb expansion teaser, dual CTA (Post a job / Become a tasker)                                                      | IN   | 8   | Was THIN 5h. Bumped to full landing per re-scope.                                                                        |
| 517    | ~~Job detail public page (SEO-indexed)~~ — **SHIPPED in S3** (SEO-01..04). Verify in S11 that production indexing is working.                                                                                                                                                          | —    | —   | Moved to Sprint 3 phase-1 SEO bundle.                                                                                    |
| 520    | **Full sitemap.xml + robots.txt + sitemap index** — generated dynamically, includes job pages, category pages, location pages, static pages. Pinged to Google Search Console + Bing on every job publish.                                                                              | IN   | 3   | Was THIN 2h.                                                                                                             |
| 521    | **Open Graph + Twitter cards on every public surface** — job pages (done in S3), landing, category pages, location pages, tasker public profiles, FAQ.                                                                                                                                 | IN   | 3   | Was THIN 2h. Already on jobs (S3).                                                                                       |
| SEO-05 | **Programmatic category × location landing pages** — `/find/cleaners-in-bondi`, `/find/plumbers-in-newtown`, etc. Generated for every (category, suburb) the platform serves, server-rendered from active jobs in that combination. Empty-state copy when no live jobs.                | IN   | 12  | The primary low-CAC organic acquisition engine.                                                                          |
| SEO-06 | **Schema.org structured data — JobPosting, LocalBusiness, FAQPage, BreadcrumbList markup across all public pages**                                                                                                                                                                     | IN   | 4   | Builds on the per-job markup from S3.                                                                                    |
| SEO-07 | **AI-generated SEO content per job (AI-07)** — Gemini Flash generates a one-paragraph SEO description from the structured job data, validated for length + tone + keyword inclusion. Cached; not regenerated unless the job is edited.                                                 | IN   | 6   | AI-07 was deferred to V2 in the first reconciliation; pulled back IN here per founder re-scope alongside the SEO bundle. |
| SEO-08 | **Cookie consent banner (legally required for any web surface)** — minimal banner, GDPR + Australian Privacy Act compliant, sets `cookies-consent` cookie, integrates with PostHog (analytics fires only after consent).                                                               | IN   | 4   | Pairs with the Flutter Web app launch — legally required the moment any web surface ships.                               |
| SEO-09 | **Web accessibility audit pass (WCAG 2.1 AA)** — Lighthouse, axe DevTools, full keyboard navigation, screen reader pass, contrast verified. Report committed to `docs/audit/web-a11y-2026-q4.md`.                                                                                      | IN   | 5   | Pairs with the mobile a11y audit (row 218 — same sprint).                                                                |
| SEO-10 | **Blog CMS scaffold (Sanity / Decap)** — lightweight headless CMS scaffold so non-technical authors can publish posts later; one seed post live at launch.                                                                                                                             | THIN | 3   | Founder-blog launch is a separate decision; scaffold lets it happen any time without a code change.                      |
| SEO-11 | **Production indexing verification** — Google Search Console verified, Bing Webmaster verified, sitemap submitted, first crawl confirmed, "noindex" headers removed from production-final build.                                                                                       | IN   | 2   |                                                                                                                          |
| SEO-18 | **Core Web Vitals optimisation** (per Estimation v1.2 audit) — LCP < 2.5s, CLS < 0.1, FID/INP < 100ms on every public page. Lighthouse CI step in build pipeline; build fails if Core Web Vitals regress. Image optimisation via Next.js `<Image>`, font preload, critical CSS inline. | IN   | 6   | SEO ranking factor — Google demotes pages with bad Core Web Vitals.                                                      |
| SEO-19 | **Analytics integration (GA4 + Meta Pixel)** (per Estimation v1.2 audit) — gated behind cookie consent (SEO-08). GA4 server-side events via Measurement Protocol. Meta Pixel via Conversions API for ad attribution. PostHog continues to handle product analytics independently.      | IN   | 4   | Marketing-side analytics — required for any paid acquisition. PII-safe configuration.                                    |

### Backend polish

| Item                                               | Hrs | Notes                                |
| -------------------------------------------------- | --- | ------------------------------------ |
| App update force-version endpoint                  | 1   | Returns minimum required app version |
| Mobile crash log forwarding to Sentry              | 1   |                                      |
| Push token rotation backend                        | 1   |                                      |
| Healthcheck + ready endpoint polish                | 1   |                                      |
| Final security review skill run on entire codebase | 2   |                                      |
| Final Semgrep + CodeQL pass                        | 2   |                                      |
| `pnpm audit` + Trivy CVE scan                      | 2   |                                      |
| Final compliance check vs docs/audit/\*.md         | 2   |                                      |

### Flutter Web final polish (added per founder direction 14 Jun 2026)

The Web app parity work landed Sprints 2-8 alongside each mobile sprint; this is the final polish + smoke test pass before launch.

| Item                                                                                                                                                                                                          | Hrs | Notes                                                                      |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --- | -------------------------------------------------------------------------- |
| **Browser smoke test matrix (Safari macOS, Safari iOS, Chrome, Edge, Firefox)** — full happy path on each browser. Confirms web parity work doesn't regress when the Flutter Web build deploys to production. | 4   | Equivalent of TestFlight + Play Store internal for web.                    |
| **Responsive polish — desktop / tablet / mobile-web breakpoints** — final pass on every screen; tighten any obviously phone-shaped layouts on desktop.                                                        | 3   |                                                                            |
| **App-shortcuts.json + PWA manifest + service worker for installability** — web app can be "installed" to home screen from Safari + Chrome.                                                                   | 3   | The web app target gets a basic PWA shell so it feels native if installed. |

**Flutter Web final polish total: ~10h**

### Pre-launch security verification (added per scope reconciliation CHANGED-ITEMS row)

The full external pen test is still scheduled for within 60 days post-launch (per [PROJECT_CONTEXT.md §11](../../PROJECT_CONTEXT.md) and [audit/vulnerability-management.md](../audit/vulnerability-management.md)). But Saiju's review correctly flagged a gap: real money + PII flows in Sprint 12 before any adversarial testing. To close that, we add a **scoped pre-launch test of payment + auth + PII** here in S11.

| Item                                                                                                                                                                                                                                                                                                                                                                                                                | Hrs | Notes                                                                                                                                                                                                                                                           |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Scoped pre-launch pen test (payment + auth + PII surfaces only)** — 2-3 day engagement with an external boutique firm. Scope: `apps/api/src/modules/auth`, `apps/api/src/modules/payments`, `apps/api/src/modules/payout`, the DSR endpoints in `apps/api/src/modules/privacy`. Out of scope: full-suite pen test (post-launch). Deliverable: written report with severity-rated findings + remediation guidance. | 6   | Engagement cost ~A$3-5k for a scoped 2-3 day boutique-firm test. Findings triaged immediately; any CRITICAL blocks Sprint 12 launch. Documented in `docs/audit/pen-test-prelaunch-2026-11.md`. Full-suite test still happens within 60d post-launch as planned. |

### Bug-fix budget

|                                               | Hrs |
| --------------------------------------------- | --- |
| Reserved for TestFlight + Play Store feedback | 15  |

**Sprint total: ~154h** (was 83h. +50h SEO bundle per founder re-scope. +10h Flutter Web final polish. +11h per Estimation v1.2 audit (SEO-18 +6, SEO-19 +4, row 196 +1). **Sprint 11 is 3 weeks; soft launch lands Fri 8 Jan 2027 — see PLAN.md.**)

## Definition of done

Same as Sprint 1, plus:

- [ ] First TestFlight build successfully installed on client's iPhone, full happy path completes
- [ ] First Play Store internal build successfully installed on a real Android, full happy path completes
- [ ] `security-review` skill final pass: no CRITICAL findings open
- [ ] `pnpm audit` shows 0 high-severity CVEs
- [ ] Trivy scan: 0 high/critical CVEs in container images
- [ ] All 19 IT audit docs have a real "Owner" field (not TODO)
- [ ] Privacy Policy + Terms of Service drafted by legal counsel OR you accept liability of using a template (document the choice)
- [ ] All ADRs 001-007 reviewed for accuracy
- [ ] PROJECT_CONTEXT.md updated reflecting actual state
- [ ] Each `apps/*/CLAUDE.md` reviewed for currency

## Friday demo script (end-of-sprint Fri 13 Nov)

3-4 min:

```
00:00 — "Sprint 11 wrap. Client hands-on the real app. Real device."
00:15 — Show TestFlight invite arrive on client's iPhone. Tap.
00:30 — Install. Show "Open" button. Tap.
00:45 — Cold-launch. Splash animation plays. Lands on welcome screen.
01:00 — Client signs up live on the call (or pre-recorded). Email +
        role + role select. Complete.
01:30 — Client posts a real job (e.g., "Assemble a desk Saturday").
01:50 — Switch to second device (Android) — tasker makes an offer.
02:10 — Client accepts the offer on iPhone.
02:25 — Chat between devices.
02:45 — Payment authorise. Test card. Test mode.
03:00 — Completion (geofence check-in + photos).
03:15 — Auto-capture. Tax invoice PDF arrives on iPhone.
03:30 — Show the app icon, splash, push notifications, App Store
        listing screenshots.
03:45 — Bug list from this sprint — what got found, what got fixed.
04:00 — Coverage report. Stoplight + asks. Plan for Sprint 12 soft
        launch. End.
```

## Risks

| Risk                                                  | Likelihood | Impact   | Mitigation                                                                                                                        |
| ----------------------------------------------------- | ---------- | -------- | --------------------------------------------------------------------------------------------------------------------------------- |
| TestFlight build rejected by Apple review             | Medium     | High     | Pre-read App Store Review Guidelines; common pitfalls: missing ATT prompt, undocumented data collection, demo account credentials |
| Android signing key mishandling                       | Medium     | High     | Use Google Play app signing; backup upload key to multiple secure locations                                                       |
| Push notifications work on sim but not on real device | Medium     | Medium   | Test early in S11; expect 4-8h of APNS / FCM debugging on real devices                                                            |
| Real device performance issues (slow on older phones) | Medium     | Medium   | Test against iPhone 11 + a $300 Android phone, not just latest sim                                                                |
| Bugs found exceed 15h budget                          | High       | Medium   | Cut THIN polish rows; defer to S12 buffer                                                                                         |
| Legal Privacy Policy / ToS isn't ready                | Medium     | Critical | Engage counsel by end of S10; template is acceptable for MVP but document liability acceptance                                    |
| App icon / screenshots look amateur                   | Low        | Low      | Use Figma + canvas templates; iterate if client unhappy                                                                           |

## Explicitly NOT in scope

- Tasker public profile page on SEO web — DROPPED (inventory row 518)
- Category landing pages — DROPPED (inventory row 519)
- Right-to-left text — DROPPED (inventory row 219)
- App-icon redesign by professional designer (use Figma + template)
- New features (anything not on the inventory)

## Day-by-day rough plan

| Day          | Mobile / Polish                                                                                       | Backend / Hardening                                                    |
| ------------ | ----------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Mon 2 (D1)   | App icon + splash + launch animation. Empty states.                                                   | Sentry SDK wired. Push token rotation backend.                         |
| Tue 3 (D2)   | Error boundaries + network retry UX. Crash reporting.                                                 | Final `security-review` skill pass on entire codebase.                 |
| Wed 4 (D3)   | Universal link verification (apple-app-site-association, assetlinks.json).                            | Trivy + `pnpm audit` + CodeQL final scans. Fix any high-sev CVEs.      |
| Thu 5 (D4)   | Analytics events (PostHog SDK). App lifecycle handling.                                               | Bug-fix budget kicks in.                                               |
| Fri 6 (D5)   | Mid-sprint demo: TestFlight + Play Store internal builds uploaded. Client receives invite.            | Mid-sprint demo + catch-up.                                            |
| Mon 9 (D6)   | App Store + Play Store listings — screenshots, descriptions, categories.                              | Client feedback bugs land — triage.                                    |
| Tue 10 (D7)  | Legal pages: ToS, Privacy, Community Guidelines, RCTI agreement, Cancellation policy.                 | Bug-fix.                                                               |
| Wed 11 (D8)  | Public web landing + job detail public page + sitemap + OG cards.                                     | Bug-fix.                                                               |
| Thu 12 (D9)  | Final polish: accessibility, biometric on sensitive actions, force-update prompt, maintenance screen. | Final compliance audit vs docs/audit/\*.md. PROJECT_CONTEXT.md update. |
| Fri 13 (D10) | End-of-sprint demo + CSV update + ADR review.                                                         | Confirm CI green. Tag `sprint-11-end`.                                 |

## Definition of "shippable"

- [ ] TestFlight build live, client has installed and completed happy path
- [ ] Play Store internal build live, tester has installed and completed happy path
- [ ] All 8 legal pages in app
- [ ] 5 SEO web rows complete (landing + public job + sitemap + OG)
- [ ] `pnpm audit` 0 high/critical
- [ ] CVE scan 0 high/critical
- [ ] All audit docs have owners
- [ ] `./scripts/coverage.sh` reports ~99% MVP
- [ ] Sprint 12 detail doc reviewed
- [ ] Switch-to-live-Stripe checklist drafted (for S12 D1)
- [ ] Mobile a11y audit report committed to `docs/audit/mobile-a11y-2026-q4.md` — critical findings fixed
- [ ] Scoped pre-launch pen test complete — written report received, CRITICAL findings fixed (or accepted with founder + dev sign-off)
- [ ] [post-mvp-deferred.md](./post-mvp-deferred.md) reviewed — every deferred item still defensible to defer; revisit triggers still correct

## Expected PRs (~12-15)

- `feat(mobile): app icon + splash + launch animation`
- `feat(mobile): error boundaries + network retry + empty states`
- `feat(mobile): Sentry crash reporting + PostHog analytics`
- `feat(mobile): universal links + ATT prompt + biometric on payment`
- `feat(mobile): force-update prompt + maintenance screen + offline indicator`
- `feat(mobile): legal pages (8 static pages)`
- `feat(mobile): accessibility — basics (semantic labels, focus order, contrast)`
- `feat(mobile): logout from all devices + send logs to support`
- `feat(web): landing page + public job page + sitemap + OG cards`
- `chore(infra): TestFlight build pipeline + Play Store internal track`
- `chore(security): final security review skill pass + CVE remediation`
- `chore(audit): IT audit docs final review — assign owners`
- `chore(docs): PROJECT_CONTEXT.md + ADRs + CLAUDE.md final review`
- `fix(*): bug-fix PRs (10-15 small PRs from TestFlight + Play feedback)`
