# JOBBees

Australian peer-to-peer task marketplace. Mobile-first (Flutter), single Node/NestJS backend, Next.js admin and public web.

## What's in this repo

```
jobbees/
├── apps/
│   ├── mobile/        # Flutter (iOS + Android) — user-facing app
│   ├── api/           # NestJS backend — business logic, all integrations
│   ├── admin/         # Next.js admin console
│   └── web/           # Next.js public/SEO pages
├── packages/
│   ├── prisma/        # Database schema + migrations
│   ├── types/         # Shared TS types (generated from API OpenAPI)
│   ├── tsconfig/      # Shared TypeScript configs
│   └── eslint-config/ # Shared ESLint config
├── docs/
│   ├── adrs/          # Architecture Decision Records
│   └── audit/         # IT audit documentation
└── ops/
    ├── docker/        # Local dev Docker Compose (Postgres + Redis)
    └── terraform/     # Azure infrastructure-as-code (post-MVP)
```

## Quick start (local development)

**Prerequisites:**

- Node.js 24.0.0+ (use `nvm install` — `.nvmrc` is pinned)
- pnpm 9.12.0+ (`npm install -g pnpm`)
- Docker Desktop (for local Postgres + Redis)
- Flutter 3.24+ (for the mobile app)

**Setup:**

```bash
# 1. Install dependencies
pnpm install

# 2. Start Postgres + Redis locally
pnpm docker:up

# 3. Copy env template and fill in any values you have
cp .env.example .env.local

# 4. Run database migrations
pnpm db:migrate:dev

# 5. (Optional) Seed dev data
pnpm db:seed

# 6. Start everything
pnpm dev
```

**Mobile app (Flutter — separate command):**

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Key documents

Read these in order before contributing:

1. **`PROJECT_CONTEXT.md`** — master context document. All architectural decisions, conventions, compliance non-negotiables. Load this first.
2. **`docs/adrs/001-monorepo-and-stack.md`** — why we made the architectural choices we made.
3. **`docs/adrs/`** — other architecture decisions as they accumulate.
4. **`docs/audit/`** — IT audit documentation templates and policies.

## Workflow

- One feature per branch: `feat/<short-name>` (e.g. `feat/ranked-feed`)
- Conventional Commits (`feat:`, `fix:`, `chore:`) — keeps history readable
- PR required to merge to `main` (branch protection enforced)
- Pre-commit hooks: gitleaks, eslint, prettier, typecheck (configured in `lefthook.yml`)
- CI on every PR: lint, test, typecheck

## Working with Claude Code

`CLAUDE.md` files at the root and inside each `apps/*` directory auto-load when Claude Code runs in that folder. Custom skills are in `.claude/skills/`.

Always use **plan mode** (`Shift+Tab` in CLI, or `/plan`) for any task above ~30 minutes of work. Run the `security-review` skill on every PR touching auth, payments, or PII.

## Australian compliance — non-negotiable

This is a payment-handling Australian marketplace. The following items cannot be skipped:

- GST + ABN + RCTI + ATO sharing-economy reporting (`apps/api/src/modules/tax`)
- Stripe Connect Express with held-funds UX, separate from KYC
- API idempotency on every mutating endpoint
- Privacy Act compliance: DSR endpoints, consent ledger, retention schema, anonymisation pipeline
- 7-year financial record retention with anonymisation
- PII redaction before external LLM calls

See `PROJECT_CONTEXT.md` §8 for the full list.
