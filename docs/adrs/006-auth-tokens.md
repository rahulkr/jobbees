# ADR-006: Auth token storage strategy

**Status:** Accepted
**Date:** 2026-06-09
**Decider:** Engineering lead
**Supersedes:** none

## Context

JOBBees has three client surfaces — Flutter mobile, Next.js admin web, Next.js public web — that all need to authenticate against the same NestJS API. Each surface has different token-storage characteristics.

A single-mechanism choice (cookie OR bearer) would force compromises on at least one surface. A surface-specific choice trades some implementation complexity for the right mechanism in each context.

## Decision

**Per-surface token storage:**

| Surface                          | Access token                                   | Refresh token                                           | CSRF protection                           |
| -------------------------------- | ---------------------------------------------- | ------------------------------------------------------- | ----------------------------------------- |
| **Mobile (Flutter)**             | Bearer in `Authorization: Bearer <jwt>` header | iOS Keychain / Android Keystore (encrypted, OS-managed) | Not needed (no browser context)           |
| **Web (Next.js admin + public)** | HttpOnly `Secure` `SameSite=Lax` cookie        | HttpOnly `Secure` `SameSite=Strict` cookie              | CSRF token in custom header for mutations |

The API issues both representations from the same `/v1/auth/login` endpoint, depending on the `Sec-Fetch-Mode` header / `X-Client-Surface: mobile|web` header sent by the client.

## Rationale

### Mobile (Bearer)

- Cookies don't work cleanly with the Flutter HTTP client (`dio`); developer experience is poor
- Mobile keychains (iOS Keychain, Android Keystore) provide OS-level encryption + biometric gate
- Bearer header is the iOS / Android industry standard
- Refresh-token rotation in a transaction (per CLAUDE.md rule 1) — refresh tokens stored in DB, denylist in Redis
- Biometric re-auth (Face ID / Touch ID) wraps Keychain access — strongest mobile pattern

### Web (HttpOnly cookie + CSRF)

- HttpOnly cookies cannot be read by JavaScript → XSS cannot steal the token
- `SameSite=Lax` protects against cross-site CSRF for navigation
- `SameSite=Strict` on refresh token (only sent on direct navigation to API)
- `Secure` flag ensures HTTPS-only
- CSRF token in a custom header for POST/PUT/PATCH/DELETE — `X-CSRF-Token` validated against session
- This is the mature, defensible web auth pattern

### Token rotation

- Access token TTL: 15 minutes
- Refresh token TTL: 30 days
- Refresh-token rotation on every refresh — old token marked `revokedAt`
- All refresh tokens stored in Postgres `RefreshToken` table for audit
- Active session denylist in Redis for instant logout-all

### Per-API-call authorization

- Every mutating endpoint guarded by `@UseGuards(JwtAuthGuard)` + `@Roles(...)`
- Role-based access (CLIENT / TASKER / ADMIN / SUPER_ADMIN) on every route
- Ownership check on resource-scoped routes (e.g., `/me/*`, `/jobs/:id/*`)

## Consequences

- Two auth code paths in the API (cookie + bearer) — adds ~3 hours over single-mechanism
- Mobile and web share the same backend logic for token issuance + verification
- Logout-all works across surfaces via Redis denylist
- Mobile biometric flow integrates with Keychain-stored access token
- The `apps/api/src/modules/auth/strategies/` directory will contain `bearer.strategy.ts` and `cookie.strategy.ts`

## Implementation notes

- Use Passport.js with both `passport-jwt` (for bearer) and a custom cookie strategy
- Issue tokens via a single `TokenIssuer` service that the auth controllers call
- All access tokens are JWTs signed with HS256 + a secret from Key Vault (Sprint 10) — dev uses `.env.local`
- Refresh tokens are opaque random tokens (32 bytes, base64url) — not JWTs — so they can be revoked
- AuditLog write on every login, logout, refresh, revoke

## Alternative considered: single-mechanism Bearer

Considered using Bearer everywhere including web — but:

- Web devs have to choose where to store the token (localStorage = XSS vulnerable; in-memory = lost on refresh)
- The "in-memory + cookie refresh" hybrid is fragile
- HttpOnly cookie is the canonical web pattern for a reason

The complexity cost of supporting two mechanisms is small compared to the security/UX benefit.

## Acceptance criteria

- [ ] `/v1/auth/login` issues bearer JWT for mobile, sets HttpOnly cookies for web
- [ ] `/v1/auth/refresh` rotates the refresh token (old revoked, new issued)
- [ ] `/v1/auth/logout` clears the session in both Redis + DB
- [ ] `/v1/auth/logout-all` adds all user tokens to Redis denylist
- [ ] Web mutation requests require `X-CSRF-Token` header
- [ ] Test: stolen access token cannot be replayed after logout
- [ ] Test: cross-site request without CSRF token is rejected

## References

- OWASP Auth Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- Passport.js: https://www.passportjs.org/
- `docs/sprints/sprint-01-onboarding-and-auth.md`
- `.claude/skills/security-review/SKILL.md` §B (AuthN/AuthZ)
