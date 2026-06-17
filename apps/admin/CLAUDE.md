# CLAUDE.md — apps/admin (Next.js admin console)

Internal operations UI. Manual-heavy by design — build the queues and viewers; do operations by hand in the UI.

## Stack

- Next.js 14+ (App Router)
- TypeScript strict
- shadcn/ui + Tailwind CSS
- React Hook Form + zod for forms
- TanStack Query for server state
- next-auth (or custom JWT bridge to the NestJS API)
- Recharts for KPI dashboards
- 2FA via TOTP (mandatory for admin login)

## Folder structure

```
apps/admin/
├── app/                              # App Router
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   └── 2fa/page.tsx
│   ├── (dashboard)/                  # auth-gated routes
│   │   ├── layout.tsx                # sidebar + auth check
│   │   ├── page.tsx                  # dashboard / KPI overview
│   │   ├── users/
│   │   ├── jobs/
│   │   ├── offers/
│   │   ├── messaging/
│   │   ├── payments/
│   │   ├── tax/
│   │   ├── disputes/
│   │   ├── reviews/
│   │   ├── content/                  # FAQ CRUD, T&Cs editor
│   │   ├── categories/
│   │   ├── cold-start/               # manual broadcast tools
│   │   ├── config/                   # platform fee, cancellation matrix, etc.
│   │   └── audit/                    # audit log viewer, DSR queue
│   └── api/                          # only for proxying to NestJS (don't put business logic here)
├── components/
│   ├── ui/                           # shadcn-generated components
│   ├── queue/                        # reusable queue list pattern
│   └── data-table/                   # reusable filterable table
├── lib/
│   ├── api.ts                        # fetch wrapper for NestJS API
│   ├── auth.ts                       # next-auth config
│   └── utils.ts
└── public/
```

## Hard rules — never violate

1. **No business logic in Next.js.** All actions call the NestJS API via `lib/api.ts`. Server Actions and Route Handlers are _only_ for: session cookies, file upload proxying, server components fetching for SSR.
2. **No direct database access.** No Prisma client in this app. The API is the only thing that touches Postgres.
3. **Server Components by default.** Use `'use client'` only when you need interactivity (form, modal, button with state). Most pages are server-rendered for speed.
4. **All admin actions are audit-logged.** The NestJS API does the audit logging — no logic here, but always pass actor identity (admin user ID + IP + user agent) on every request.
5. **2FA mandatory.** Admin can't log in without TOTP. No "remember me" beyond 8 hours.
6. **Sensitive data redacted by default.** PII in lists shows as `+61•••••1234` style. Click-to-reveal logs the access.
7. **Refunds processed in admin portal**, not the Stripe dashboard. Build the refund UI; it calls the NestJS `/payments/refund` endpoint with `Idempotency-Key`.
8. **Tier-0 mediator + admin co-pilot render in the disputes UI.** They display backend-generated recommendations — don't re-implement the LLM logic on the frontend.
9. **No client-side LLM calls.** All AI features call backend endpoints.
10. **Mass-message / broadcast UI is DROP at MVP.** Use an external tool. Don't build this.

## Conventions

- **Forms:** React Hook Form + zod schema. Schema lives alongside the form component.
- **API calls:** TanStack Query for reads, mutations for writes. Always include `Idempotency-Key` on mutations.
- **Tables:** shadcn `<DataTable>` with column definitions. Filters as URL search params (shareable links).
- **Error states:** every page has a `error.tsx` boundary. Loading states via Suspense + skeletons.
- **Confirmations:** destructive actions require a confirmation modal with the user typing the resource ID to confirm.
- **Roles:** at MVP single admin role. Don't pre-build granular RBAC — that's POST.

## Authentication flow

1. Admin opens `/login` → enters email + password → API returns `{ requires2fa: true, challengeToken }`.
2. Admin enters TOTP code on `/2fa` → API returns JWT + refresh token.
3. JWT stored in HTTP-only cookie (via next-auth or custom).
4. All API calls include the JWT automatically via `lib/api.ts` fetch wrapper.
5. Session timeout: 8 hours absolute, 30 min idle. Re-auth required for sensitive actions (refund > $500, user ban, dispute resolution).

## Run

- `pnpm --filter @jobbees/admin dev` — local dev on port 3001
- `pnpm --filter @jobbees/admin build`
- `pnpm --filter @jobbees/admin start`
- `pnpm --filter @jobbees/admin lint`
- `pnpm --filter @jobbees/admin typecheck`

## Hosting

- Azure App Service (same as API and web)
- Behind Azure Front Door or App Service auth restrictions
- IP allowlist for prod (post-MVP)
