# Sprint 9 — Admin console end-to-end

**Dates:** Mon 12 Oct → Fri 23 Oct 2026 (10 working days)
**Theme:** The full admin Next.js console — KYC review, License review queue (full UI; scaffold landed in S4), dispute mediation, refund processing, content moderation, FAQ + categories CRUD, payment + tax tooling, configuration.
**Hours budget:** ~85 (75 admin, 10 backend tweaks)
**Mid-sprint demo:** Fri 16 Oct
**End-of-sprint demo:** Fri 23 Oct

## Goal in one sentence

By Friday 16 Oct, an admin can log in, see today's queue, click through to KYC reviews, resolve disputes using the AI co-pilot, process refunds, manage FAQs and categories, tune ranking weights + Tier-0 threshold, and download the monthly ATO report — all from the Next.js admin console.

## Scope — inventory rows

### Admin (apps/admin) — almost the whole sprint

| ID  | Item                                                       | Call | Hrs | Notes                                                                                                                               |
| --- | ---------------------------------------------------------- | ---- | --- | ----------------------------------------------------------------------------------------------------------------------------------- |
| 421 | Admin 2FA (TOTP, mandatory)                                | IN   | 4   | Hard requirement before merge                                                                                                       |
| 422 | Role-based access (single admin role at MVP)               | THIN | 2   |                                                                                                                                     |
| 423 | Audit log of admin actions                                 | THIN | 3   |                                                                                                                                     |
| 425 | Admin user CRUD                                            | THIN | 2   |                                                                                                                                     |
| 426 | KPI overview (DAU, tasks, GMV, payouts, disputes)          | THIN | 4   |                                                                                                                                     |
| 427 | System health (error rate, latency)                        | THIN | 3   | Embed Sentry/App Insights                                                                                                           |
| 428 | Today's queue (KYC pending, disputes, flagged content)     | IN   | 3   |                                                                                                                                     |
| 429 | User list with search / filter                             | IN   | 5   |                                                                                                                                     |
| 430 | User detail view (profile, tasks, bids, reviews, payments) | IN   | 6   |                                                                                                                                     |
| 431 | KYC review queue (full UI; scaffold was S2)                | IN   | 4   | Approve/reject/needs more                                                                                                           |
| 534 | License review queue (full UI; scaffold was S2)            | IN   | 5   | Per-category trade licenses. Approve/reject/needs more. Cross-check against AU state register (NSW Fair Trading etc.). See ADR 005. |
| 432 | Connect onboarding tracker                                 | IN   | 3   |                                                                                                                                     |
| 433 | Suspend / ban user                                         | IN   | 2   |                                                                                                                                     |
| 434 | Reinstate user                                             | IN   | 1   |                                                                                                                                     |
| 435 | Manual identity verification override                      | IN   | 2   |                                                                                                                                     |
| 436 | Force logout                                               | THIN | 1   |                                                                                                                                     |
| 437 | Reset password (admin-triggered)                           | THIN | 1   |                                                                                                                                     |
| 441 | GDPR / DSR request handler                                 | IN   | 5   | Admin tool to action DSR queue                                                                                                      |
| 442 | Task list with filter                                      | IN   | 4   |                                                                                                                                     |
| 443 | Task detail / edit / delete                                | IN   | 3   |                                                                                                                                     |
| 444 | Content moderation queue (flagged)                         | IN   | 4   |                                                                                                                                     |
| 445 | Manual approval workflow                                   | THIN | 2   |                                                                                                                                     |
| 446 | Re-categorise task                                         | THIN | 1   |                                                                                                                                     |
| 447 | Force-cancel task                                          | IN   | 1   |                                                                                                                                     |
| 448 | Edit AI extraction results                                 | THIN | 2   |                                                                                                                                     |
| 449 | Bid list per task                                          | THIN | 2   |                                                                                                                                     |
| 450 | Public Q&A moderation queue                                | THIN | 2   |                                                                                                                                     |
| 452 | Flagged messages queue                                     | IN   | 4   |                                                                                                                                     |
| 453 | Manual message review interface                            | IN   | 3   |                                                                                                                                     |
| 454 | Thread freeze / unfreeze                                   | THIN | 1   |                                                                                                                                     |
| 455 | Payment list with filter                                   | IN   | 4   |                                                                                                                                     |
| 456 | Payment detail                                             | IN   | 3   |                                                                                                                                     |
| 457 | Refund processing in admin portal (full + partial)         | IN   | 8   |                                                                                                                                     |
| 458 | Manual capture / void                                      | IN   | 3   |                                                                                                                                     |
| 459 | Payout tracking (Stripe Connect data embedded)             | THIN | 2   |                                                                                                                                     |
| 460 | Held-funds dashboard (by tasker, by total)                 | IN   | 3   |                                                                                                                                     |
| 461 | Reconciliation report (daily)                              | THIN | 2   |                                                                                                                                     |
| 462 | Stripe webhook delivery log                                | THIN | 2   |                                                                                                                                     |
| 463 | Promo code admin (CRUD, usage tracking)                    | IN   | 6   |                                                                                                                                     |
| 464 | Tax invoice listing                                        | THIN | 2   |                                                                                                                                     |
| 465 | RCTI status per tasker                                     | IN   | 3   |                                                                                                                                     |
| 466 | RCTI re-generation                                         | THIN | 2   |                                                                                                                                     |
| 467 | ATO report preview / download                              | IN   | 4   |                                                                                                                                     |
| 468 | ATO submission log                                         | IN   | 2   |                                                                                                                                     |
| 469 | GST rate config                                            | IN   | 1   |                                                                                                                                     |
| 470 | Tax adjustment / manual override log                       | THIN | 1   |                                                                                                                                     |
| 471 | Dispute queue                                              | IN   | 3   |                                                                                                                                     |
| 472 | Tier-0 mediator suggestion panel                           | IN★  | 4   | Renders backend mediator output                                                                                                     |
| 473 | Manual mediation interface                                 | IN   | 4   |                                                                                                                                     |
| 474 | Evidence viewer (photos, messages, completion proof)       | IN   | 4   |                                                                                                                                     |
| 475 | Resolution actions (release, partial, refund, escalate)    | IN   | 3   |                                                                                                                                     |
| 476 | Admin notes per dispute                                    | IN   | 2   |                                                                                                                                     |
| 477 | Admin co-pilot brief renderer                              | IN★  | 4   | Renders backend co-pilot output                                                                                                     |
| 478 | Dispute history per user                                   | THIN | 1   |                                                                                                                                     |
| 480 | Review queue (flagged / reported)                          | IN   | 3   |                                                                                                                                     |
| 481 | Manual review removal                                      | IN   | 1   |                                                                                                                                     |
| 484 | RAG agent conversation history viewer                      | THIN | 4   | Defer to S11 if tight                                                                                                               |
| 485 | FAQ CRUD (drives RAG agent + mobile FAQ)                   | IN   | 5   |                                                                                                                                     |
| 486 | FAQ categories                                             | THIN | 2   |                                                                                                                                     |
| 487 | Help article CRUD                                          | THIN | 2   |                                                                                                                                     |
| 488 | T&Cs / Privacy Policy versioned editor                     | THIN | 2   | Markdown                                                                                                                            |
| 489 | Push notification composer (ad-hoc broadcast)              | THIN | 3   |                                                                                                                                     |
| 490 | Banner / announcement composer (in-app)                    | THIN | 3   |                                                                                                                                     |
| 491 | Category CRUD                                              | IN   | 3   |                                                                                                                                     |
| 492 | Sub-category CRUD                                          | THIN | 2   |                                                                                                                                     |
| 493 | Skill tag CRUD                                             | THIN | 2   |                                                                                                                                     |
| 494 | Service area CRUD (suburbs, postal codes)                  | IN   | 3   |                                                                                                                                     |
| 495 | Marketplace KPI dashboard (Mixpanel/PostHog embedded)      | THIN | 3   |                                                                                                                                     |
| 497 | Platform fee config (per category)                         | IN   | 2   |                                                                                                                                     |
| 498 | Cancellation fee matrix config                             | IN   | 2   |                                                                                                                                     |
| 499 | Auto-confirm timing config                                 | IN   | 1   |                                                                                                                                     |
| 500 | Tier-0 dispute threshold ($ cap)                           | IN   | 1   |                                                                                                                                     |
| 501 | Stripe credentials / keys (display only)                   | IN   | 1   |                                                                                                                                     |
| 502 | LLM provider config + model selection                      | THIN | 2   |                                                                                                                                     |
| 503 | Feature flags (env-based booleans)                         | THIN | 2   |                                                                                                                                     |
| 504 | Maintenance mode toggle                                    | THIN | 1   |                                                                                                                                     |
| 505 | Rate-limit config (per endpoint / per tier)                | IN   | 2   |                                                                                                                                     |
| 506 | Geographic launch toggle (per suburb)                      | THIN | 2   |                                                                                                                                     |
| 507 | Manual broadcast tool (push a task to candidate taskers)   | IN   | 5   |                                                                                                                                     |
| 508 | Tasker invitation tool (admin-issued invite codes)         | THIN | 3   |                                                                                                                                     |
| 511 | Admin action audit log viewer                              | THIN | 2   |                                                                                                                                     |
| 512 | User action audit trail viewer                             | THIN | 2   |                                                                                                                                     |
| 513 | Data retention dashboard                                   | THIN | 2   |                                                                                                                                     |
| 514 | DSR request queue                                          | IN   | 3   |                                                                                                                                     |
| 515 | Consent ledger viewer                                      | THIN | 2   |                                                                                                                                     |

**Admin total: ~75h** (compress relentlessly — many THIN rows; ship a working surface for each, polish in S11)

### Backend (minor)

| ID                       | Item                          | Call | Hrs | Notes                             |
| ------------------------ | ----------------------------- | ---- | --- | --------------------------------- |
| 423 (backend supporting) | Admin action audit log writes | THIN | 3   | Hook into existing AuditLog model |
| Admin RBAC               | RBAC role + middleware        | THIN | 2   | Single ADMIN role at MVP          |

## Schema additions

- New `AdminTotp` model (from FUTURE MODELS): `userId @id`, `secretEncrypted`, `enabledAt DateTime?`, `lastUsedAt DateTime?`, `backupCodesHashed Json`
- New `BannedUser` model? No — use `User.suspendedAt + User.suspensionReason` (we added to FUTURE MODELS in Sprint 0 retrospective; finalise in S9)
- Add to User: `suspendedAt DateTime?`, `suspensionReason String?`, `bannedAt DateTime?`, `bannedReason String?`, `reinstatedAt DateTime?`
- New `AdminBroadcast` model: `id`, `createdById`, `audienceFilter Json`, `channel ENUM(PUSH, EMAIL, SMS, IN_APP)`, `subject String?`, `body Text`, `sentAt DateTime?`, `recipientCount Int?`
- New `ConfigKvp` model for admin-tunable config: `key @id`, `valueJson Json`, `description Text?`, `updatedAt`, `updatedById`

## Definition of done

Same as Sprint 1, plus:

- [ ] Admin 2FA mandatory — cannot disable, cannot log in without TOTP code (skill §B)
- [ ] Every admin action writes to AuditLog with actorId, action, target, before/after (skill §I)
- [ ] Admin pages use server-side auth check (Next.js middleware) — no client-only guards
- [ ] Sensitive admin tools (refund, suspend, key display) require fresh re-auth (5min window)
- [ ] Admin RBAC role check on every API call from admin

## Friday demo script (end-of-sprint Fri 16 Oct)

5-6 min:

```
00:00 — "Sprint 9 wrap. Full admin console. A day in the life of admin."
00:15 — Admin login → TOTP code from authenticator → land on dashboard.
00:35 — Today's queue: KYC pending (3), disputes (1), flagged content
        (2), DSR requests (1). System health: green.
00:55 — KYC review: open one. View Stripe Connect status + ABN check
        result. Approve. Notification fires to user. Status updates.
01:05 — License review: open a pending plumbing license. View uploaded
        license photo + claimed license number + claimed expiry + issuing
        state (NSW). Cross-check against NSW Fair Trading public register
        (link shown). Approve. Tasker gets "Verified Plumber" badge and
        can now bid on plumbing tasks.
01:20 — Dispute queue: open the dispute from Sprint 7. See Tier-0
        mediator suggestion panel with proposal + rationale + cost.
        See admin co-pilot case brief: timeline, key messages, evidence,
        precedent, recommendation. Resolve manually with "Partial release
        70% to tasker".
02:00 — Refund processing: payment list → filter by "completed" → open
        a payment → tap Refund → enter partial amount $50 → Stripe call
        fires → state PARTIAL_REFUNDED → AuditLog entry written.
02:30 — Content moderation: queue shows the flagged photo from Sprint 8.
        Decision: Reject. Task author notified.
02:55 — Promo code admin: create code WELCOME15 (15% off, 100 uses,
        expires 30 days). Save. Track usage on existing codes.
03:15 — Tax tooling: download monthly ATO report. Show CSV format.
        ATO submission log shows past months.
03:35 — Configuration: tune ranking weights (open ranking weight admin
        sliders). Tune Tier-0 threshold from $200 → $250. Adjust
        cancellation fee matrix. Save → backend picks up new values.
04:00 — User suspension: open a user, click Suspend, enter reason.
        Audit log entry. User receives notification on next login.
04:15 — DSR queue: open a pending DSR access request → tap "Process"
        → backend job runs → file ready → download link.
04:30 — Manual broadcast: compose a push to "all taskers in Sydney"
        about a category change. Preview audience. Send (test).
04:45 — Admin action audit log viewer: show last 50 actions taken
        across all admins. Filter by action type.
05:00 — Coverage report. Stoplight + asks. End.
```

## Risks

| Risk                                        | Likelihood | Impact   | Mitigation                                                                                           |
| ------------------------------------------- | ---------- | -------- | ---------------------------------------------------------------------------------------------------- |
| Admin scope is huge — 50+ rows              | High       | High     | Triage relentlessly: ship working surface for every row, polish in S11. Don't perfect any one screen |
| Admin 2FA implementation has security holes | Low        | Critical | Use `speakeasy` or `otplib` (battle-tested) + skill §B + manual code review                          |
| TOTP secret storage not encrypted at rest   | Low        | High     | Encrypt via Azure Key Vault (S10) or pre-encrypt in DB with key from env                             |
| Admin actions don't audit-log               | Medium     | High     | Centralise via interceptor; CI test ensures every mutation endpoint writes                           |
| Reconciliation report inaccurate            | Medium     | Medium   | Tax advisor reviews; mark THIN and refine in S11                                                     |
| Single ADMIN role doesn't scale             | Low (MVP)  | Low      | Documented as MVP simplification; multi-role in post-MVP                                             |

## Explicitly NOT in scope

- Impersonate user (login as) — DROPPED (inventory row 438)
- Bulk operations — DROPPED (inventory row 439)
- Merge duplicate accounts — DROPPED (inventory row 440)
- Ticket queue UI — POST (inventory row 483)
- Funnel / cohort / LTV / churn / surge analytics — POST (inventory row 496)
- Referral code management — DROPPED (inventory row 510)
- Synthetic supply seeding workflow — MANUAL (inventory row 509)
- Tier-0 dispute precedent retrieval — THIN (inventory row 339)
- Multi-admin role variants — POST (single ADMIN at MVP)

## Day-by-day rough plan

| Day          | Admin (Next.js)                                                                                                                                               | Backend (assist)                                                                                                            |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Mon 5 (D1)   | Admin scaffolding: auth + TOTP setup + RBAC middleware.                                                                                                       | AdminTotp model. Admin action audit log hooks.                                                                              |
| Tue 6 (D2)   | Dashboard + today's queue + KPI thin panels.                                                                                                                  | Aggregation endpoints for KPI panel.                                                                                        |
| Wed 7 (D3)   | User list + detail. KYC review queue (full UI). **License review queue** (full UI — per ADR 005). Connect tracker.                                            | Suspend/ban + reinstate endpoints. License approval endpoint (writes AuditLog + transitions PENDING → APPROVED / REJECTED). |
| Thu 8 (D4)   | Task list + detail + edit/delete. Content moderation queue.                                                                                                   | Force-cancel + edit AI extraction endpoints.                                                                                |
| Fri 9 (D5)   | Mid-sprint demo + catch-up.                                                                                                                                   | Same.                                                                                                                       |
| Mon 12 (D6)  | Payment list + detail + refund + manual capture/void. Held-funds dashboard.                                                                                   | Refund endpoint polish + reconciliation aggregation.                                                                        |
| Tue 13 (D7)  | Tax: tax invoice listing + RCTI status + ATO preview/download. Promo codes admin.                                                                             | Promo code engine polish (started S6).                                                                                      |
| Wed 14 (D8)  | Dispute queue + Tier-0 panel + co-pilot brief renderer + manual mediation + evidence viewer + resolution.                                                     | Dispute admin endpoints.                                                                                                    |
| Thu 15 (D9)  | FAQ CRUD + category CRUD + service areas + config (fee matrix, ranking weights, Tier-0 threshold, etc.). DSR queue + audit log viewer. Manual broadcast tool. | Config service (ConfigKvp).                                                                                                 |
| Fri 16 (D10) | End-of-sprint demo + CSV update.                                                                                                                              | Confirm CI green. Tag `sprint-09-end`.                                                                                      |

## Definition of "shippable"

- [ ] All ~70 admin rows have working surface (THIN rows may have rough UI; IN rows polished)
- [ ] Admin 2FA enforced on every login
- [ ] Every admin mutation logs to AuditLog
- [ ] KYC approval end-to-end works (admin → mobile notification)
- [ ] License approval end-to-end works (tasker uploads → admin approves → tasker can bid on licensed-trade tasks; AuditLog written)
- [ ] Dispute resolution end-to-end works (admin → both parties notified)
- [ ] Refund processing end-to-end works (admin → Stripe → AuditLog → notifications)
- [ ] ATO report download works
- [ ] `./scripts/coverage.sh` reports ~94% MVP
- [ ] Sprint 10 detail doc reviewed
- [ ] Cloudflare / Azure Front Door decision recorded → ADR 007

## Expected PRs (~18-22, smaller diffs)

Smaller PRs this sprint — many feature surfaces, each ~150-200 LOC:

- `feat(prisma): AdminTotp, BannedUser fields, AdminBroadcast, ConfigKvp`
- `feat(api/admin): TOTP setup + verify endpoints + RBAC middleware`
- `feat(api/admin): audit log interceptor for admin actions`
- `feat(api/admin): suspend/ban/reinstate endpoints`
- `feat(api/admin): force-cancel task + edit extraction endpoints`
- `feat(api/admin): refund + manual capture/void endpoints`
- `feat(api/admin): config service (ConfigKvp) + rate-limit/ranking-weight tuning`
- `feat(api/admin): manual broadcast endpoint`
- `feat(admin/dashboard): KPI panels + today's queue + system health`
- `feat(admin/users): list + detail + KYC review + license review queue + Connect tracker`
- `feat(admin/users): suspend/ban + force-logout + reset password + DSR queue`
- `feat(admin/tasks): list + detail + edit + content moderation + force-cancel`
- `feat(admin/messages): flagged queue + manual review + thread freeze`
- `feat(admin/payments): list + detail + refund + manual capture/void + held-funds`
- `feat(admin/tax): tax invoice listing + RCTI + ATO preview/download + GST config`
- `feat(admin/disputes): queue + Tier-0 panel + co-pilot brief + manual mediation`
- `feat(admin/reviews): queue + manual removal`
- `feat(admin/content): FAQ + categories + service areas + skill tags + T&Cs`
- `feat(admin/config): fee matrix + ranking weights + Tier-0 threshold + feature flags`
- `feat(admin/growth): manual broadcast + tasker invitation tool`
- `feat(admin/audit): admin action audit log viewer + user audit + consent ledger viewer`
