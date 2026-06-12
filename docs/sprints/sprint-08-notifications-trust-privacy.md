# Sprint 8 — Notifications + Trust/Safety + Privacy

**Dates:** Mon 28 Sep → Fri 9 Oct 2026 (10 working days)
**Theme:** Push notifications fire reliably across the lifecycle, content moderation + EXIF detection catch suspicious uploads, rate limits + PII redaction protect the API + AI layer, and DSR endpoints make the Privacy Act story real.
**Hours budget:** ~85 (25 mobile, 60 backend)
**Mid-sprint demo:** Fri 2 Oct
**End-of-sprint demo:** Fri 9 Oct

## Goal in one sentence

By Friday 2 Oct, every meaningful event (bid accepted, payment captured, dispute opened, KYC approved) fires a push + optional email/SMS fallback; suspicious task photos get flagged via Azure Content Safety + EXIF analysis; users can export and delete their data via in-app DSR endpoints that honour the 7-year financial retention rule.

## Scope — inventory rows

### Mobile (apps/mobile)

| ID  | Item                                                | Call | Hrs | Notes                              |
| --- | --------------------------------------------------- | ---- | --- | ---------------------------------- |
| 168 | Push notifications (FCM / APNS setup)               | IN   | 4   |                                    |
| 169 | In-app notification center                          | IN   | 4   |                                    |
| 170 | Per-channel toggle (push / email / SMS)             | THIN | 2   |                                    |
| 172 | Email opt-out unsubscribe link (rendering)          | IN   | 1   | Backend handles token              |
| 173 | SMS opt-out (STOP keyword)                          | IN   | 1   | Mostly backend                     |
| 174 | Notification badges                                 | IN   | 1   |                                    |
| 175 | Deep-link from notification → screen                | IN   | 2   |                                    |
| 176 | Critical-state SMS/email fallback (mobile handling) | IN   | 1   | Mobile receives; backend escalates |
| 185 | Privacy / data download (DSR access)                | IN   | 3   |                                    |
| 186 | Account deletion request                            | IN   | 3   |                                    |

**Mobile total: ~22h**

### Backend (apps/api)

| ID  | Item                                               | Call | Hrs | Notes                                 |
| --- | -------------------------------------------------- | ---- | --- | ------------------------------------- |
| 341 | Push notification service (FCM + APNS)             | IN   | 5   |                                       |
| 342 | Email service (SendGrid)                           | IN   | 4   |                                       |
| 343 | SMS service (Notifyre)                             | IN   | 4   |                                       |
| 344 | In-app notification queue / API                    | IN   | 4   |                                       |
| 345 | User preferences engine (per-channel)              | THIN | 3   |                                       |
| 346 | Notification templates (push / email / SMS)        | IN   | 4   |                                       |
| 347 | Critical-state fallback escalation                 | IN   | 4   | push → email → SMS                    |
| 348 | Spam Act compliance (opt-out, unsubscribe)         | IN   | 2   |                                       |
| 349 | Unsubscribe token endpoint                         | IN   | 2   |                                       |
| 351 | Image content moderation (Azure Content Safety)    | IN   | 6   |                                       |
| 352 | Async moderation queue (borderline confidence)     | IN   | 3   |                                       |
| 353 | EXIF tampering / consistency check                 | IN   | 8   | EXIF + GPS + date plausibility        |
| 355 | Rate limiting middleware (per-user + per-endpoint) | IN   | 4   |                                       |
| 356 | LLM cost telemetry + anomaly alerts                | IN   | 3   |                                       |
| 357 | Account suspension webhooks                        | IN   | 2   |                                       |
| 358 | Data inventory + retention schema per table        | IN   | 5   |                                       |
| 359 | DSR endpoints (access, delete, correct)            | IN   | 8   |                                       |
| 360 | Anonymisation job (financial retained 7y)          | IN   | 6   |                                       |
| 361 | Hard delete vs anonymise logic                     | IN   | 3   |                                       |
| 362 | Consent ledger                                     | IN   | 5   |                                       |
| 364 | PII redaction layer before external LLM calls      | IN   | 3   | Already exists in skeleton — finalise |

**Backend total: ~88h** (tight — manage scope carefully)

### Schema additions

- New `NotificationPreference` model (from FUTURE MODELS): `userId`, `pushEnabled Boolean`, `emailEnabled Boolean`, `smsEnabled Boolean`, `criticalSmsFallback Boolean @default(true)`, plus `@@id([userId])`
- New `NotificationLog` model: `id`, `userId`, `channel ENUM(PUSH, EMAIL, SMS, IN_APP)`, `templateKey`, `subject String?`, `bodyPreview String?`, `eventType`, `sentAt`, `deliveredAt DateTime?`, `failedAt DateTime?`, `failureReason String?`
- New `UnsubscribeToken` model: `id`, `userId`, `channel`, `tokenHash String @unique`, `createdAt`, `usedAt DateTime?`
- New `ContentModerationResult` model: `id`, `taskPhotoId String?`, `userId`, `provider String // "azure-content-safety"`, `category ENUM(HATE, VIOLENCE, SEXUAL, SELF_HARM, OK)`, `confidence Float`, `flaggedForReview Boolean`, `createdAt`, `reviewedAt DateTime?`, `reviewerDecision ENUM?`
- New `RateLimitBucket` model? No — keep in Redis
- New `ConsentRecord` model: `id`, `userId`, `consentType ENUM(MARKETING, TOS, PRIVACY_POLICY, RCTI_AGREEMENT)`, `version`, `acceptedAt`, `ipAddress`, `userAgent`, `withdrawnAt DateTime?`
- New `DsrRequest` model: `id`, `userId`, `type ENUM(ACCESS, DELETE, CORRECT)`, `status ENUM(PENDING, IN_PROGRESS, COMPLETED, REJECTED)`, `submittedAt`, `completedAt DateTime?`, `exportBlobUrl String?` (for ACCESS requests)
- New `DsrAction` model: `id`, `dsrRequestId`, `action`, `targetTable`, `targetRecordCount`, `performedAt`, `performedByJobId`

## Definition of done

Same as Sprint 1, plus per skill §F + §J + §K + the privacy audit doc:

- [ ] Every external LLM call goes through `redactPii()` — automated test enforces this (skill §F1)
- [ ] No PII in logs — `pino.redact` configured with `[email, phone, fullName, address, abn, etc.]` (skill §F2)
- [ ] Daily LLM cost cap per user enforced; anomaly alert fires if global daily cost exceeds threshold (skill §J1)
- [ ] Anti-prompt-injection wrap on user-supplied text passed to LLMs (skill §J2)
- [ ] Rate limits applied: `/auth/*` 5/min, `/payment/*` 60/min/user, `/ai/*` 60/min/user (skill §D)
- [ ] DSR access endpoint returns ALL user data in a structured JSON within 24h (Privacy Act compliance)
- [ ] DSR delete endpoint anonymises user; financial records retained 7 years per ATO requirement
- [ ] Consent ledger captures every consent transition with version + IP + UA (skill §K)
- [ ] Acceptance test: insert 100 task photos with various EXIF anomalies, ≥80% caught by EXIF check

## Friday demo script (end-of-sprint Fri 2 Oct)

5 min:

```
00:00 — "Sprint 8 wrap. Notifications, trust + safety, privacy. The
        plumbing that makes everything else compliant."
00:15 — Notification demo: trigger 4 lifecycle events back-to-back on
        Device A (poster):
          - Bid received
          - Payment captured
          - Dispute opened
          - KYC approved (admin-triggered)
        Show each push notification arriving + tap → deep-links to the
        correct screen.
01:00 — Notification preferences: open settings → toggle SMS off,
        email off. Trigger same events → push only.
01:20 — Critical state demo: simulate "push delivery failed" (turn
        airplane mode on) → backend escalates to email → email arrives.
        If email also fails, SMS fires.
01:40 — Email unsubscribe: click unsubscribe link in delivered email
        → opens browser → backend handles token → confirmation page.
        Verify subsequent events don't email this user.
02:00 — SMS STOP: reply "STOP" to a test SMS → backend records opt-out
        → subsequent events don't SMS.
02:20 — Content moderation: poster posts a task with a problematic
        image (e.g., a clearly-faked AI image) → Azure Content Safety
        flags → admin moderation queue receives the flag.
02:40 — EXIF tampering: poster posts a task with photo modified in
        Photoshop. EXIF analysis flags "edited by Adobe Photoshop"
        → admin queue receives it.
03:00 — Switch to admin: review the moderation queue, approve/reject.
03:15 — DSR access: switch back to user. Settings → Privacy & data
        → Download my data → wait 60s → file ready → download. Show
        the structured JSON content (all bids, tasks, messages, payments,
        reviews — but no other users' PII).
03:40 — DSR delete: Settings → Privacy & data → Delete my account.
        Confirmation flow. Backend anonymises user (financial rows
        retained but PII removed). Show audit log entry.
04:00 — Consent ledger: admin view shows the user's accepted consents
        with versions + timestamps + IPs.
04:15 — LLM cost telemetry: dashboard shows daily cost per feature,
        per-user top consumers, anomaly alert fired flag.
04:30 — Coverage report. Stoplight + asks. End.
```

## Risks

| Risk                                                  | Likelihood | Impact   | Mitigation                                                                     |
| ----------------------------------------------------- | ---------- | -------- | ------------------------------------------------------------------------------ |
| Azure Content Safety adds cost — small but real       | Medium     | Low      | Budget ~$5-15/mo at MVP scale; document in S10 cost projection                 |
| EXIF false positives on legitimate iPhone HEIC photos | Medium     | Medium   | Test against 100 real iPhone photos; tune confidence thresholds                |
| DSR endpoint exposes other users' PII accidentally    | Low        | Critical | Manual code review + skill §F4; integration test checks for cross-user leaks   |
| Anonymisation breaks financial reconciliation         | Low        | High     | Test against ATO-sample export; tax advisor sign-off on anonymisation strategy |
| Push delivery success rate < 95%                      | Medium     | Medium   | Monitor in S10 App Insights; escalation cadence covers gaps                    |
| LLM cost anomaly false positives                      | Medium     | Low      | Alert threshold tunable in admin (S9)                                          |
| 7-year retention contradicts user's deletion request  | Low        | Medium   | Privacy Policy documents the distinction; admin DSR queue handles edge cases   |

## Explicitly NOT in scope

- Per-category granular prefs (marketing vs transactional) — DROPPED (inventory row 171)
- Notification history / replay — THIN (inventory row 177) — defer to S9
- 2FA for users — POST (inventory row 182)
- Language switcher — POST (inventory row 187)
- Theme — POST shape; light only at MVP (inventory row 188 already in S1)
- Behavioural fraud detection — POST (inventory row 354)
- LLM-ops tooling (Langfuse / Helicone) — POST (inventory row 370)
- Eval harness — POST (inventory row 371)
- Audit log retention (admin tool) — THIN (inventory row 365)

## Day-by-day rough plan

| Day            | Mobile                                             | Backend                                                         |
| -------------- | -------------------------------------------------- | --------------------------------------------------------------- |
| Mon 21 (D1)    | FCM/APNS setup + permission priming.               | Notification service skeleton + templates.                      |
| Tue 22 (D2)    | In-app notification center.                        | Push delivery (FCM/APNS). Email (SendGrid). SMS (Notifyre).     |
| Wed 23 (D3)    | Notification preferences UI + per-channel toggle.  | Critical-state fallback escalation cron. Spam Act compliance.   |
| Thu 24 (D4)    | Deep-link from notification + notification badges. | Unsubscribe token + endpoint. Rate limiting middleware.         |
| Fri 25 (D5)    | Mid-sprint demo + catch-up.                        | Same.                                                           |
| Mon 28 (D6)    | DSR access download UI.                            | Azure Content Safety integration. Async moderation queue.       |
| Tue 29 (D7)    | Account deletion request UI.                       | EXIF tampering check. LLM cost telemetry.                       |
| Wed 30 (D8)    | Polish + bug fixes.                                | DSR endpoints (access). Anonymisation job + 7y retention logic. |
| Thu 1 Oct (D9) | Email opt-out unsubscribe + SMS STOP rendering.    | DSR delete + consent ledger. PII redaction layer finalise.      |
| Fri 2 (D10)    | End-of-sprint demo + CSV update.                   | Confirm CI green. Tag `sprint-08-end`.                          |

## Definition of "shippable"

- [ ] All 10 mobile rows done
- [ ] All 21 backend rows done
- [ ] All 4 lifecycle events fire push → push test successful
- [ ] Critical-state fallback test passes (push fail → email)
- [ ] Content moderation test: 100 photos with 10 problematic → ≥9 caught
- [ ] EXIF test: 100 photos with 10 tampered → ≥8 caught
- [ ] DSR access: returns user data within 24h (test against seeded user)
- [ ] DSR delete: anonymises within 24h, retains financial 7y
- [ ] PII redaction: 100% of external LLM calls verified
- [ ] `./scripts/coverage.sh` reports ~88% MVP
- [ ] Sprint 9 detail doc reviewed

## Expected PRs (~15-18)

- `feat(prisma): NotificationPreference, NotificationLog, UnsubscribeToken, ContentModerationResult, ConsentRecord, DsrRequest, DsrAction`
- `feat(api/notifications): push (FCM + APNS) + email (SendGrid) + SMS (Notifyre)`
- `feat(api/notifications): in-app queue + preferences engine`
- `feat(api/notifications): templates + critical-state fallback escalation`
- `feat(api/notifications): Spam Act compliance + unsubscribe token`
- `feat(api/trust): Azure Content Safety integration + async moderation queue`
- `feat(api/trust): EXIF tampering + consistency check`
- `feat(api/trust): rate limiting middleware (per-user + per-endpoint)`
- `feat(api/ai): LLM cost telemetry + anomaly alerts`
- `feat(api/privacy): DSR endpoints (access, delete, correct)`
- `feat(api/privacy): anonymisation job + 7y retention logic`
- `feat(api/privacy): consent ledger + PII redaction layer finalise`
- `feat(mobile): push setup + notification center + badges`
- `feat(mobile): notification preferences UI`
- `feat(mobile): deep-link handling`
- `feat(mobile): DSR download + account deletion request`
