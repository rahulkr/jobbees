# Sprint 6 — Job execution + Completion + Tax/RCTI/GST/ATO

**Dates:** Mon 31 Aug → Fri 11 Sep 2026 (10 working days)
**Theme:** A tasker arrives on-site, checks in via geofence, completes the job with proof, auto-capture fires, tax invoice + RCTI generated as PDF, ATO report aggregates monthly.
**Hours budget:** ~95 (40 mobile, 55 backend)
**Mid-sprint demo:** Fri 4 Sep
**End-of-sprint demo:** Fri 11 Sep

**⚠️ Tax-critical sprint. Tax advisor must be engaged BEFORE start.** CLAUDE.md rule 4 mandates advisor review of every line of RCTI/GST/ATO code before merge. Engage by end of Sprint 5 — too late if you wait until Sprint 6 starts.

## Goal in one sentence

By Friday 4 Sep, tasker arrives on-site → geofence check-in records arrival → marks job complete with 2 photos + checklist → auto-capture fires (or 48h dispute window starts) → tax invoice PDF generated for poster, RCTI PDF generated for tasker, both downloadable → monthly ATO export job aggregates all completed payments for sharing-economy reporting.

## Scope — inventory rows

### Mobile (apps/mobile)

| ID  | Item                                                              | Call | Hrs | Notes                                   |
| --- | ----------------------------------------------------------------- | ---- | --- | --------------------------------------- |
| 99  | Accepted task / job-in-progress screen                            | IN   | 3   |                                         |
| 100 | Status update buttons (en route, arrived, in progress, completed) | IN   | 2   |                                         |
| 101 | Geofenced check-in / arrival proof                                | IN   | 4   | Location permission + geofence logic    |
| 102 | Live location share during active job (opt-in)                    | IN   | 5   | UI; backend in S5                       |
| 103 | Completion proof upload (2 photos + checklist)                    | IN   | 4   |                                         |
| 104 | Completion proof — optional 30s video                             | THIN | 3   |                                         |
| 105 | Time tracking (start / stop / total)                              | THIN | 2   |                                         |
| 134 | Receipt PDF view / download                                       | IN   | 2   |                                         |
| 135 | Tax invoice PDF (poster)                                          | IN   | 2   |                                         |
| 136 | Tax invoice / RCTI PDF (tasker)                                   | IN   | 2   |                                         |
| 137 | RCTI agreement screen                                             | IN   | 2   |                                         |
| 138 | Refund request (poster initiates from app)                        | IN   | 3   |                                         |
| 139 | Re-auth prompt (capture-expiry approaching)                       | IN   | 4   |                                         |
| 140 | Tip / gratuity option                                             | THIN | 2   |                                         |
| 141 | Promo code / discount input                                       | IN   | 5   | Code entry, validation, applied display |
| 142 | Cancellation flow with fee preview                                | IN   | 6   |                                         |
| 143 | Poster-initiated cancel                                           | IN   | 1   |                                         |
| 144 | Tasker-initiated cancel                                           | IN   | 1   |                                         |
| 145 | Mutual cancellation request                                       | THIN | 2   |                                         |
| 146 | Reason picker                                                     | IN   | 1   |                                         |
| 147 | Fee disclosure / confirmation step                                | IN   | 1   |                                         |
| 148 | No-show reporting (poster / tasker)                               | IN   | 3   |                                         |

**Mobile total: ~60h**

### Backend (apps/api)

| ID  | Item                                               | Call | Hrs | Notes                               |
| --- | -------------------------------------------------- | ---- | --- | ----------------------------------- |
| 305 | GST calculation on platform fee                    | IN   | 4   | Single AU GST rate (10%) at MVP     |
| 306 | ABN status tracking + re-check cron                | IN   | 3   |                                     |
| 307 | RCTI generation + PDF                              | IN   | 8   | pdfkit; tax advisor review required |
| 308 | RCTI agreement workflow + consent capture          | IN   | 3   |                                     |
| 309 | Tax invoice generation + PDF (poster)              | IN   | 4   |                                     |
| 310 | Tax invoice / RCTI PDF (tasker)                    | IN   | 3   |                                     |
| 311 | ATO sharing-economy reporting export (monthly job) | IN   | 8   | All mandatory fields, CSV/JSON      |
| 313 | Tax-rate config (single GST rate)                  | IN   | 2   |                                     |
| 314 | Cancellation engine with fee matrix                | IN   | 8   |                                     |
| 315 | Fee calculation logic                              | IN   | 3   |                                     |
| 316 | No-show detection — poster                         | IN   | 3   |                                     |
| 317 | No-show detection — tasker                         | IN   | 3   |                                     |
| 318 | Geofenced check-in verification                    | IN   | 3   |                                     |
| 319 | Auto-confirm cron job                              | IN   | 4   | 48h dispute window                  |
| 320 | Dispute window cron (48h)                          | IN   | 3   |                                     |
| 321 | Escalating notification cadence                    | IN   | 4   |                                     |
| 322 | State transitions for all cancel scenarios         | IN   | 4   |                                     |

**Backend total: ~70h**

### Schema additions

- New `TaxInvoice` model: `id`, `paymentId`, `recipientType ENUM(POSTER, TASKER)`, `recipientUserId`, `amountCents`, `gstCents`, `totalCents`, `pdfBlobUrl`, `invoiceNumber String @unique`, `issuedAt`, `taxPeriod`
- New `Rcti` model: `id`, `paymentId`, `taskerId`, `taskerName`, `taskerAbn String?`, `taskerAddress`, `taxiPayerName`, `feeCents`, `gstCents`, `totalCents`, `pdfBlobUrl`, `rctiNumber String @unique`, `issuedAt`, `agreementId`
- New `RctiAgreement` model: `id`, `taskerId`, `acceptedAt`, `version`, `ipAddress`, `userAgent`
- New `AtoExport` model: `id`, `period String // "2026-09"`, `recordCount`, `totalGrossCents`, `filePath`, `generatedAt`, `submittedAt DateTime?`
- New `Cancellation` model: `id`, `taskId`, `initiatorId`, `initiatorRole ENUM(POSTER, TASKER, ADMIN)`, `reason`, `feeCents`, `notes`, `createdAt`
- New `CompletionProof` model: `id`, `taskId`, `taskerId`, `photoBlobUrls Json`, `videoBlobUrl String?`, `checklistJson Json`, `geofenceVerifiedAt DateTime?`, `latitude`, `longitude`, `createdAt`
- New `PromoCode` + `PromoCodeUsage` models (from FUTURE MODELS): `PromoCode(id, code @unique, discountType, discountValue, maxUses, expiresAt, isActive)`, `PromoCodeUsage(id, promoCodeId, userId, paymentId, usedAt)`

## Definition of done

Same as Sprint 1, plus per skill §H + §K + PR template tax section:

- [ ] GST calculation lives in `apps/api/src/modules/tax/gst.service.ts` — no inline math anywhere else (skill §H3)
- [ ] RCTI triggered on payout, NOT on bid accept (skill §H4)
- [ ] ABN validated via `validateAbn()` before any DB write (skill §K2)
- [ ] Sharing-economy reporting fields populated for every tasker payment: `taskerName`, `taskerAbn` (or `noAbnReason`), `taskerAddress`, `totalEarningsCents`, period (skill §K3)
- [ ] **Tax advisor sign-off documented in each tax-related PR description** (CLAUDE.md rule 4)
- [ ] AuditLog write on every Payment capture, refund, cancellation, no-show
- [ ] PDF generation uses `pdfkit` (or `puppeteer` if HTML→PDF is cleaner) — pick once, document in ADR
- [ ] ATO export job test: seeded 50 payments across 2 months → export → manual review confirms format matches ATO schema

## Friday demo script (end-of-sprint Fri 4 Sep)

5-6 min screencast:

```
00:00 — "Sprint 6 wrap. Job execution + tax. End-to-end with PDFs."
00:15 — Device B (tasker): open accepted-task screen. Show status:
        Ready to start.
00:30 — Walk into the geofence area (simulate via dev tool). Tap
        "I've arrived". Geofence verification fires. Status: Arrived.
00:45 — Tap "Start job". Show optional live location share toggle.
        Enable. Show real-time tracking in poster's app.
01:00 — Switch to A (poster): see tasker's location updating in real
        time.
01:15 — Time tracker shows elapsed. Mark complete on B.
01:30 — Completion proof screen: upload 2 photos (before + after).
        Checklist ticked (e.g., "site cleaned up", "materials disposed").
        Optional 30s video. Submit.
01:50 — Backend: auto-confirm cron sets a 48h dispute window. State:
        AWAITING_AUTO_CONFIRM.
02:00 — Fast-forward 48h via dev tool: auto-capture fires. Payment
        state: CAPTURED.
02:15 — Device A (poster): receive notification "Payment captured".
        Open transaction history → tap → view tax invoice PDF.
        Download. Show the rendered PDF.
02:30 — Device B (tasker): receive notification "RCTI ready". View RCTI
        PDF. Download. Show rendered PDF with: tasker name, ABN, address,
        amount, GST, RCTI agreement clause.
02:50 — Show RCTI agreement screen for a first-time tasker (consent
        capture flow): "Agree to recipient-created tax invoice"
        → checkbox → accept.
03:05 — Refund flow: poster requests partial refund. Admin approves.
        Payment state: PARTIAL_REFUNDED. Tax invoice + RCTI adjusted.
03:20 — Cancellation flow: poster cancels task at 12h before scheduled
        time. Fee preview shows "50% tasker compensation".
        Confirm. Cancellation recorded, fee debited.
03:35 — No-show flow: tasker doesn't check in within X hours. Auto-
        notification escalates to poster. Tasker penalty applied.
03:50 — Admin: export ATO report for current month. Download CSV.
        Show preview.
04:05 — Promo code: poster enters PROMO20 → 20% discount applied to
        next task payment. Show validation flow.
04:20 — Coverage report. Stoplight + asks. End.
```

## Risks

| Risk                                       | Likelihood | Impact   | Mitigation                                                                                     |
| ------------------------------------------ | ---------- | -------- | ---------------------------------------------------------------------------------------------- |
| Tax advisor unavailable mid-sprint         | Medium     | Critical | Engage by EOD Fri 21 Aug (Sprint 5 end); confirm availability for daily review during Sprint 6 |
| RCTI format wrong per ATO requirements     | Medium     | Critical | Use ATO published RCTI sample as the source of truth; tax advisor reviews template before code |
| GST rounding edge cases (10c → 10.01c?)    | Medium     | Medium   | Banker's rounding; document in `gst.service.ts` comments; tax advisor signs off                |
| Geofence check-in fails on poor GPS        | Medium     | Low      | Fallback: tasker can manually flag "I'm here" if GPS confidence low; admin reviews if disputed |
| PDF generation slow under load             | Low        | Low      | Background job; user gets push when ready                                                      |
| ATO export schema changes                  | Low        | High     | Wrap schema in `atoExportV1` namespace; if ATO changes, add `atoExportV2`                      |
| Cancellation fee matrix disputed by client | Medium     | Low      | Tax advisor reviews fee structure; recordable in admin config (S9)                             |

## Explicitly NOT in scope

- Job extension / reschedule request — DROPPED (inventory row 106)
- In-app voice/video call — DROPPED (inventory row 107)
- Live location share UI on poster side — Sprint 7 scoping? Actually already in S6 (row 102 covered)
- Annual tax summary per user — THIN (inventory row 312) — defer to S9/S11 admin polish
- Tax adjustment / manual override log — THIN (inventory row 470) — defer to S9 admin

## Day-by-day rough plan

| Day            | Mobile                                                | Backend                                                  |
| -------------- | ----------------------------------------------------- | -------------------------------------------------------- |
| Mon 24 (D1)    | Accepted task + status update buttons.                | Tax models (TaxInvoice, Rcti, RctiAgreement, AtoExport). |
| Tue 25 (D2)    | Geofence check-in + arrival proof.                    | GST service. Geofence verification.                      |
| Wed 26 (D3)    | Completion proof: photo upload + checklist.           | RCTI PDF generation (tax advisor review at EOD).         |
| Thu 27 (D4)    | Live location share UI + completion proof video.      | Tax invoice PDF generation.                              |
| Fri 28 (D5)    | Mid-sprint demo + catch-up.                           | Same. Auto-confirm cron + dispute window.                |
| Mon 31 (D6)    | Refund request + re-auth prompt UI.                   | Cancellation engine + fee matrix.                        |
| Tue 1 Sep (D7) | Cancellation flow + reason picker + fee preview.      | Fee calculation logic. No-show detection (both).         |
| Wed 2 (D8)     | Promo code input + validation. RCTI agreement screen. | ATO export job. Escalating notification cadence.         |
| Thu 3 (D9)     | Polish + tax invoice + RCTI viewing screens.          | Promo code engine. Audit logs. State transitions polish. |
| Fri 4 (D10)    | End-of-sprint demo + CSV update.                      | Confirm CI green. Tag `sprint-06-end`.                   |

## Definition of "shippable"

- [ ] All 22 mobile rows done
- [ ] All 17 backend rows done
- [ ] Tax invoice PDF + RCTI PDF generated for a test transaction; both visually validated by tax advisor
- [ ] ATO export job runs against seeded data; output schema matches ATO spec
- [ ] GST rounding test passes for 100 representative amounts
- [ ] Cancellation matrix test passes for all 4 scenarios (early/late, poster/tasker)
- [ ] No-show end-to-end test passes
- [ ] `./scripts/coverage.sh` reports ~72% MVP
- [ ] Sprint 7 detail doc reviewed

## Expected PRs (~15-18)

- `feat(prisma): TaxInvoice, Rcti, RctiAgreement, AtoExport, Cancellation, CompletionProof, PromoCode`
- `feat(api/tax): GST service (single rate, banker's rounding)`
- `feat(api/tax): tax invoice generation + PDF (tax advisor sign-off)`
- `feat(api/tax): RCTI generation + PDF (tax advisor sign-off)`
- `feat(api/tax): RCTI agreement workflow + consent capture`
- `feat(api/tax): ATO sharing-economy reporting export job (tax advisor sign-off)`
- `feat(api/tax): ABN status tracking + re-check cron`
- `feat(api/jobs): cancellation engine + fee matrix`
- `feat(api/jobs): no-show detection + escalating cadence`
- `feat(api/jobs): geofence check-in verification`
- `feat(api/jobs): auto-confirm + dispute window crons`
- `feat(api/payments): promo code engine`
- `feat(mobile): accepted job + status updates + geofence check-in`
- `feat(mobile): completion proof (photos + checklist + video)`
- `feat(mobile): tax invoice + RCTI + RCTI agreement viewing`
- `feat(mobile): refund + re-auth + cancellation + no-show`
- `feat(mobile): promo code input`
