# ADR-008: OTP / SMS strategy

**Status:** 🟡 Partially decided — pattern locked, vendor for production SMS still open
**Date:** 2026-06-09
**Decider:** Engineering lead + client (production SMS vendor)
**Supersedes:** none

## Context

JOBBees needs SMS for two distinct purposes:

1. **Phone OTP verification** — only for taskers (not clients), fires once at tasker upgrade or signup. Inventory rows 13, 234.
2. **SMS notifications** — critical-state fallback (push fails → email fails → SMS), STOP-keyword opt-out, alphanumeric sender for trust. Inventory rows 173, 343, 348.

These are _separable_ concerns. They could be the same vendor or different vendors.

A third concern: **dev workflow**. We don't want Sprint 1 blocked waiting for a vendor account, real SMS quota burn during local dev, or SMS provider keys in the repo. The mock-then-swap pattern solves this.

## Decision (locked)

### Architecture — `OtpService` interface + provider abstraction

Implement an `OtpService` interface in NestJS that the auth + KYC modules depend on:

```typescript
export interface OtpService {
  sendOtp(phone: string): Promise<{ requestId: string }>;
  verifyOtp(phone: string, code: string, requestId: string): Promise<boolean>;
}
```

Two implementations behind an env-controlled factory:

| Implementation                 | When                          | Behaviour                                                                                                  |
| ------------------------------ | ----------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **`MockOtpService`**           | Dev + staging (Sprint 1-4)    | Accepts hardcoded code `000000` for any phone. Logs `MOCK OTP for +61400000000: 000000`. No real SMS sent. |
| **`<RealProvider>OtpService`** | Production (Sprint 5 cutover) | Real SMS via the chosen vendor (Firebase Phone Auth OR alternative — see below)                            |

Provider chosen at runtime via env: `OTP_PROVIDER=mock` or `OTP_PROVIDER=<real>`.

### Safety guards (all three required, non-negotiable)

1. **Startup assertion** in `apps/api/src/main.ts`:

   ```typescript
   if (process.env.NODE_ENV === 'production' && process.env.OTP_PROVIDER === 'mock') {
     throw new Error('FATAL: OTP_PROVIDER=mock is forbidden in production');
   }
   ```

2. **Semgrep rule** in `ops/security/semgrep-rules.yml` (already added — `jobbees-mock-otp-in-prod-env`) blocks `OTP_PROVIDER=mock` from appearing in `.env.production*` or `.env.staging*` files.

3. **AuditLog** every OTP send + verify with provider name (so post-hoc verification confirms no mock OTPs in prod).

### Sprint timeline

- Sprint 1: build `OtpService` interface + `MockOtpService` + safety guards
- Sprint 2-4: use mock for all auth/tasker testing
- Sprint 5: swap to real provider, verify in test mode before any payment flow

### Decision: SMS notifications (separate from OTP)

**Notifyre** (already locked) for transactional SMS notifications with registered alphanumeric sender ID "JOBBEES". Submitted alpha sender application has 5-7 day approval lead time — start now, use from Sprint 8.

This is independent of the OTP provider choice. Even if OTP runs through Firebase, notifications run through Notifyre.

## Decision (still open)

### Which OTP vendor for production SMS?

**🟡 Open.** Three viable options, to be decided before Sprint 5 Day 1 (Mon 10 Aug 2026).

#### Option A — Firebase Phone Auth

|                           |                                                                                                                         |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Cost (AU)                 | $0.02 USD per SMS (10/day free → 300/mo free)                                                                           |
| Setup                     | Firebase project + Admin SDK in `apps/api`                                                                              |
| Sender                    | Google's pooled international long numbers (NOT branded)                                                                |
| Build effort              | ~3 hours                                                                                                                |
| AU compliance             | Spam Act exempt (transactional); Privacy Act covered via vendor docs                                                    |
| Deliverability concern    | AU carriers (Telstra/Optus/Vodafone) increasingly filter pooled international senders — ~5-10% delivery issues possible |
| Sender ID Registry future | Currently fine; ACMA tightening expected 2025-2027                                                                      |

Source: https://cloud.google.com/identity-platform/pricing (verified 2026-06-09)

#### Option B — Notifyre direct for OTP

|                |                                                                                                          |
| -------------- | -------------------------------------------------------------------------------------------------------- |
| Cost (AU)      | ~$0.06 AUD per SMS                                                                                       |
| Setup          | Notifyre account + API key (already needed for notifications)                                            |
| Sender         | Registered alphanumeric "JOBBEES" — branded, trusted                                                     |
| Build effort   | ~6 hours (build internal OTP service: generate code, store in Redis with TTL, send via Notifyre, verify) |
| AU compliance  | Native AU vendor, AU sender ID, all compliance native                                                    |
| Deliverability | Higher than Firebase due to registered AU sender                                                         |
| Single-vendor  | Yes — one SMS vendor for OTP + notifications                                                             |

#### Option C — Twilio Verify

|                |                                                           |
| -------------- | --------------------------------------------------------- |
| Cost (AU)      | ~$0.05 USD per verification (includes the SMS)            |
| Setup          | Twilio account + Verify API                               |
| Sender         | Twilio short code or alphanumeric (registration required) |
| Build effort   | ~4 hours (turnkey API, no own code/store needed)          |
| AU compliance  | Mature, well-trusted globally                             |
| Deliverability | Industry-leading; Twilio runs the carrier relationships   |
| Notes          | Higher cost than Firebase, but proven globally            |

## Recommended path

**Recommendation: Option B (Notifyre direct for OTP).** Same vendor as notifications, branded sender, better AU deliverability, and ~3 extra hours of build is small compared to the lifetime trust + deliverability win.

Backup: if Notifyre's API turns out to have issues, fall back to Option A (Firebase) — cheaper and quicker.

Either way, the `OtpService` interface means the swap is a config + ~3h implementation change in Sprint 5.

## What we are NOT deciding now

- Which vendor to actually use in production — wait until Sprint 5 with real testing in mind
- Whether to add MFA / 2FA — POST per inventory row 182
- Whether to use OTP via Signal / WhatsApp Business — out of scope at MVP

## Consequences

- Sprint 1 ships with mock OTP — accepts `000000`
- No external dependencies blocking Sprint 1-4
- Sprint 5 includes a 3-6 hour task to swap in the real provider
- Whoever we pick, the `OtpService` interface stays unchanged

## Implementation checklist

- [x] Interface defined in `packages/types` — Sprint 1 (to-be-built)
- [x] `MockOtpService` impl in Sprint 1 — to be built D1
- [x] Startup assertion in `main.ts` — Sprint 1 D1
- [x] `.env.example` has `OTP_PROVIDER` documented — done
- [x] Semgrep rule blocks mock in prod env files — done
- [ ] **Decision**: pick production vendor by **Mon 10 Aug 2026 (Sprint 5 D1)**
- [ ] Real OTP service implementation — Sprint 5
- [ ] AuditLog includes provider name — Sprint 5
- [ ] Sprint 5 demo includes swap verification

## References

- `.env.example` — `OTP_PROVIDER` documentation
- `ops/security/semgrep-rules.yml` rule `jobbees-mock-otp-in-prod-env`
- `docs/sprints/sprint-01-onboarding-and-auth.md` Decision D4
- `docs/sprints/sprint-05-messaging-payments.md` row 530
- `.claude/skills/security-review/SKILL.md` (D4 check — pending manual add)
- Firebase pricing: https://cloud.google.com/identity-platform/pricing
- Notifyre pricing: https://www.notifyre.com.au/pricing
- Twilio Verify pricing: https://www.twilio.com/en-us/verify/pricing
