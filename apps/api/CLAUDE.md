# CLAUDE.md — apps/api (NestJS backend)

This is the single source of truth for business logic. Mobile, admin, and web are all clients of this API — they never contain business logic.

## Stack

- NestJS 10+ on Node 22, TypeScript strict mode
- Prisma + PostgreSQL 16 (with pgvector)
- Redis (sessions, rate limits, idempotency, BullMQ jobs)
- Socket.IO (single-node at MVP; Redis adapter post-launch)
- Stripe + Stripe Connect Express + Stripe Identity
- Gemini Flash + Claude Sonnet (LLMs)

## Folder structure

```
apps/api/src/
├── main.ts                  # bootstrap
├── app.module.ts            # root module
├── common/                  # cross-cutting: filters, guards, interceptors, pipes
│   ├── idempotency/         # idempotency middleware (Redis-backed)
│   ├── audit/               # audit log service
│   ├── pii/                 # PII redaction for LLM calls
│   └── soft-delete/         # Prisma extension for soft-delete filtering
├── modules/                 # feature modules — one per product domain
│   ├── auth/                # JWT, OAuth, OTP, KYC orchestration
│   ├── users/               # user + tasker profile CRUD
│   ├── tasks/               # task CRUD, AI extraction, embeddings
│   ├── bids/                # bid CRUD, state machine
│   ├── matching/            # vector + ranked feed, auto-invite
│   ├── threads/             # messaging, Socket.IO gateway, chat policing
│   ├── payments/            # Stripe, state machine, idempotency
│   ├── tax/                 # GST, RCTI, ATO sharing-economy reporting
│   ├── cancellation/        # cancellation engine, no-show, auto-confirm
│   ├── reviews/             # blind review with timeout-reveal
│   ├── disputes/            # Tier-0 LLM mediator, admin co-pilot
│   ├── notifications/       # push, email, SMS, preferences, Spam Act
│   ├── trust/               # image moderation, EXIF, rate limits
│   ├── privacy/             # DSR, consent ledger, anonymisation
│   ├── ai/                  # LLM provider interface, prompt management, cost tracking
│   └── admin/               # admin-only endpoints
└── jobs/                    # BullMQ workers (auto-confirm, embeddings, ATO export, etc.)
```

One module per domain. Module file structure:
```
modules/<name>/
├── <name>.module.ts
├── <name>.controller.ts
├── <name>.service.ts
├── dto/
└── <name>.service.spec.ts
```

## Hard rules — never violate

1. **Every mutating endpoint requires the idempotency middleware.** Add `@UseInterceptors(IdempotencyInterceptor)` or use the global guard. Caller must send `Idempotency-Key` header.
2. **All Stripe calls go through `StripeService`.** Never import the Stripe SDK directly in a controller. Wrapper handles idempotency keys, error mapping, audit logging.
3. **All LLM calls go through `LlmService`.** Never call provider SDKs directly. Wrapper handles PII redaction, cost tracking, rate limits, retries.
4. **Raw SQL only for vector similarity + analytical queries.** Use `prisma.$queryRaw` with parameterised template tag. Everything else uses the Prisma client.
5. **Structured JSON logs only.** Use `Logger` from `@nestjs/common`. Never `console.log`. Never log PII.
6. **PII redaction before external LLM calls.** Use `PiiRedactionService.scrub()` on any user content sent to Gemini/Anthropic/OpenAI.
7. **Audit log on every sensitive write.** User suspension, refund, KYC override, dispute resolution, manual capture, force-cancel. Use `AuditLogService.record()`.
8. **Every controller endpoint has a DTO** with class-validator decorators. Never accept raw `any`.
9. **Transactions for multi-step writes.** Use `prisma.$transaction([...])`. Especially for payment + audit log + state transition.
10. **Rate limit AI endpoints aggressively.** Per-user quota, daily cost cap, anomaly alerts.

## Conventions

- **Errors:** throw `HttpException` subclasses (`BadRequestException`, `ForbiddenException`, etc.). Global exception filter maps to consistent response shape.
- **Validation:** `class-validator` on DTOs. `ValidationPipe` global with `whitelist: true, forbidNonWhitelisted: true`.
- **Auth:** JWT in `Authorization` header. `@CurrentUser()` decorator extracts the user from the request. `@UseGuards(JwtAuthGuard)` on protected routes.
- **Permissions:** `@Roles('TASKER', 'POSTER')` decorator with `RolesGuard`. Never check roles inline.
- **OpenAPI:** every controller has `@ApiOperation` and DTOs have `@ApiProperty`. We generate `packages/types` from this spec.
- **Environment:** access via `ConfigService`, never `process.env` directly. Validated on boot.

## Database conventions (from PROJECT_CONTEXT.md §9)

- cuid2 IDs (set in app code, not DB default)
- Money in cents (Int, never Decimal/Float)
- UTC in DB, Australia/Sydney in UI
- Soft delete on user-facing entities (deletedAt)
- Foreign key indexes are manual (Prisma doesn't auto-add)
- Audit log table is append-only
- Vector columns use `Unsupported("vector(1536)")`

## Testing

- Unit tests for services: `*.service.spec.ts`
- E2E tests for critical flows: `test/e2e/*.e2e-spec.ts`
- Use a separate test database (Postgres in Docker, separate compose service)
- Never mock Stripe in integration tests — use Stripe test mode with real test keys
- Test data via seed fixtures, not inline

## Run

- `pnpm --filter @jobbees/api dev` — start in watch mode
- `pnpm --filter @jobbees/api test` — run tests
- `pnpm --filter @jobbees/api build` — production build
- `pnpm db:migrate:dev` — run pending migrations + regenerate client
- `pnpm db:studio` — open Prisma Studio
