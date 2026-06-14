# Sprint 11 — TestFlight + Play Store internal + bug-fix + launch hardening

**Dates:** Mon 9 Nov → Fri 20 Nov 2026 (10 working days)
**Theme:** First time real human hands hold the app on real devices. Whatever breaks, fix it. Legal / store listings / SEO go in. App is ready to face actual paying users.
**Hours budget:** ~69 (29 mobile polish, 10 backend polish, 15 bug-fix budget, 15 launch hardening) — bumped from 60 to include contextual tooltips, "How it works" page, and beefed-up empty states
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

| ID  | Item                                                           | Call | Hrs | Notes                                                                                                                                                            |
| --- | -------------------------------------------------------------- | ---- | --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 70  | Re-post / clone job                                            | THIN | 1   |                                                                                                                                                                  |
| 84  | Job search bar — polish                                        | THIN | 1   |                                                                                                                                                                  |
| 153 | Blind review with timeout-reveal — polish                      | THIN | 1   |                                                                                                                                                                  |
| 156 | Edit / delete own review (within window)                       | THIN | 1   |                                                                                                                                                                  |
| 167 | Dispute history per user                                       | THIN | 1   |                                                                                                                                                                  |
| 177 | Notification history / replay                                  | THIN | 2   |                                                                                                                                                                  |
| 183 | Linked accounts view + unlink                                  | THIN | 2   |                                                                                                                                                                  |
| 184 | Notification preferences — polish                              | THIN | 2   |                                                                                                                                                                  |
| 189 | Logout from all devices                                        | THIN | 1   |                                                                                                                                                                  |
| 195 | Report a bug / feedback form                                   | THIN | 2   |                                                                                                                                                                  |
| 197 | Send logs to support                                           | THIN | 2   |                                                                                                                                                                  |
| 209 | App update prompt (soft / force)                               | IN   | 2   |                                                                                                                                                                  |
| 210 | Maintenance mode screen                                        | THIN | 1   |                                                                                                                                                                  |
| 211 | Offline indicator                                              | THIN | 2   |                                                                                                                                                                  |
| 212 | Offline draft persistence (jobs only)                          | THIN | 3   |                                                                                                                                                                  |
| 213 | Empty states — **expanded scope: act as contextual tutorials** | IN   | 5   | Was 3; +2 for instructive copy + illustrations on every empty state                                                                                              |
| 214 | Error boundary screens                                         | IN   | 2   |                                                                                                                                                                  |
| 215 | Network retry / loader UX                                      | IN   | 2   |                                                                                                                                                                  |
| 216 | Crash reporting (Sentry SDK)                                   | IN   | 2   |                                                                                                                                                                  |
| 217 | Analytics events (PostHog / Mixpanel SDK)                      | IN   | 3   |                                                                                                                                                                  |
| 218 | Accessibility — basics                                         | THIN | 4   | WCAG 2.1 AA bare minimum                                                                                                                                         |
| 220 | Background tasks (location during active job)                  | IN   | 3   |                                                                                                                                                                  |
| 221 | App lifecycle handling (background / foreground)               | IN   | 2   |                                                                                                                                                                  |
| 222 | Biometric prompt on payment / sensitive action                 | THIN | 2   |                                                                                                                                                                  |
| 223 | Push token rotation                                            | IN   | 2   |                                                                                                                                                                  |
| 224 | Universal link verification setup                              | IN   | 2   | apple-app-site-association + assetlinks.json                                                                                                                     |
| 225 | App icon, splash, launch animation                             | IN   | 2   |                                                                                                                                                                  |
| 226 | App Store / Play Store listings + screenshots                  | IN   | 4   |                                                                                                                                                                  |
| 227 | App Tracking Transparency prompt (iOS)                         | IN   | 1   |                                                                                                                                                                  |
| 528 | **Contextual tooltips on first use (5-6 key moments)**         | IN   | 5   | New: first-time-only tooltips on offer placement, accept offer, held funds, completion proof, AI-matched badge. Track "seen" via local storage. Auto-dismiss 4s. |
| 529 | **"How it works" static help page**                            | IN   | 2   | New: single screen explaining post / offer / payment / become-tasker. Linked from empty states + Help menu.                                                      |

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

### Public web (apps/web) — SEO + landing

| ID  | Item                                 | Call | Hrs | Notes                 |
| --- | ------------------------------------ | ---- | --- | --------------------- |
| 516 | Public marketing landing page        | THIN | 5   | Hero + features + CTA |
| 517 | Job detail public page (SEO-indexed) | THIN | 5   |                       |
| 520 | Sitemap.xml + robots.txt             | THIN | 2   |                       |
| 521 | Open Graph / Twitter cards           | THIN | 2   |                       |

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

### Bug-fix budget

|                                               | Hrs |
| --------------------------------------------- | --- |
| Reserved for TestFlight + Play Store feedback | 15  |

**Sprint total: ~85h** (overruns the 60 budget — relentlessly cut THIN rows if needed)

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
