# JOBBees API — Postman / REST client

The API contract is published as an **OpenAPI 3 spec** at
[`apps/api/openapi.json`](../openapi.json), generated from the live NestJS
routes:

```bash
pnpm --filter @jobbees/api export:openapi
```

We commit the OpenAPI spec rather than a vendored `*.postman_collection.json`:
it's the single source of truth (regenerated from code, reviewable in diffs),
and every modern REST client imports it into a full collection natively.

## Import into Postman

**File → Import →** select `apps/api/openapi.json`. Postman builds a collection
with every endpoint grouped by tag (`auth`, `admin`, `health`), including
request bodies and the Bearer auth scheme. (Insomnia / Bruno / Hoppscotch
import the same file.)

## Auth quickstart

All mutating requests require an `Idempotency-Key` header (any unique string).

1. `POST /auth/signup` → `{ accessToken, refreshToken }`
2. Set the collection's Bearer token to `accessToken`
3. `GET /auth/me`
4. `POST /auth/refresh` (rotates the refresh token); `POST /auth/logout` or
   `/auth/logout-all` to revoke
5. OTP (tasker): `POST /auth/otp/send` then `/auth/otp/verify` with `000000`
   (dev MockOtpService)
