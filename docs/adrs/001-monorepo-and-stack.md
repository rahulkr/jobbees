# ADR-001: Monorepo and Stack Choices

**Status:** Accepted
**Date:** 2026-05-20
**Decider:** Engineering lead (with client sign-off implicit in proposal acceptance)

## Context

Australian peer-to-peer job marketplace with payments, AI-native matching, and multi-platform clients (Flutter mobile, Next.js admin + web). Tight initial timeline, max-AI coding workflow (Claude Code primary).

Need to lock the stack and structure on day one so the codebase doesn't drift as it scales.

## Decision

### Monorepo (pnpm workspaces + Turborepo)

One git repository containing:

- `apps/api` — NestJS backend (single source of truth for business logic)
- `apps/mobile` — Flutter (managed outside pnpm; uses pubspec.yaml)
- `apps/admin` — Next.js admin console
- `apps/web` — Next.js public/SEO pages
- `packages/prisma` — DB schema + migrations
- `packages/types` — generated TS types from API OpenAPI
- `packages/tsconfig`, `packages/eslint-config` — shared configs

### Backend: Node.js + NestJS + TypeScript

Chose NestJS over Express/Fastify/Hono because:

- Opinionated structure prevents drift as the codebase grows
- Module pattern maps 1:1 to product domains (auth, jobs, offers, payments...)
- Decorators + DI generate dense, consistent AI code with low hallucination
- Built-in OpenAPI generation feeds `packages/types` for free
- Mature production patterns; loads of training data for AI codegen

### Database: PostgreSQL 17 + pgvector + Prisma ORM

- PostgreSQL chosen for: maturity, JSON support, pgvector extension, Azure managed offering
- pgvector for embeddings — no separate vector database; one DB, one connection pool, one backup
- Prisma chosen over Drizzle/TypeORM/Sequelize because:
  - Schema-as-code via `schema.prisma`
  - Automatic migrations (`prisma migrate dev`)
  - Type-safe client; very low AI hallucination on Prisma calls
  - Prisma Studio for ad-hoc dev DB browsing
- Raw SQL via `prisma.$queryRaw` only for vector similarity searches and analytical queries

### Mobile: Flutter + Riverpod + go_router + dio

- Flutter for single codebase across iOS + Android
- Riverpod over Bloc/Provider — cleaner async story, best AI codegen support
- go_router for declarative routing with auth-aware redirects
- dio for HTTP with interceptors (auth, error mapping, retry)

### Admin + public web: Next.js 14 (App Router)

- One framework, two apps — share patterns and components
- App Router for Server Components by default (fast, less JS to ship)
- shadcn/ui + Tailwind for owned UI components (AI can modify freely)
- Both apps are _clients_ of the NestJS API — no business logic, no direct DB access

### Auth: Custom JWT (no Auth0/Clerk)

- AU data residency simpler with self-hosted auth
- No vendor lock for the most critical part of the system
- Bcrypt + JWT + Postgres sessions is well-trodden ground
- Phone OTP separate decision (Firebase Phone Auth vs Twilio Verify — pending client sign-off, see open decisions in PROJECT_CONTEXT.md)

### Payments: Stripe + Stripe Connect Express + Stripe Identity

Single vendor for the full payment flow: PaymentIntent, SetupIntent, Refund, Connect Express (tasker payouts), Stripe Identity (KYC).

### Hosting: Azure (full stack)

- Client preference; existing Azure DevOps relationship
- Azure App Service for the three TS apps
- Azure Database for PostgreSQL Flexible Server with pgvector
- Azure Cache for Redis
- Azure Blob Storage for media
- Azure Key Vault for secrets
- Azure Application Insights for logs + APM
- Azure Content Safety for image moderation

Portability planned via Terraform IaC + abstracted storage/queue/log layers. Migration to AWS or GCP is a project, not a feature — design for it but don't pre-pay the cost.

### CI/CD: GitHub Actions (not Azure DevOps)

- Portable across clouds
- Better Flutter + Node + Docker support out of the box
- Dependabot, CodeQL, Trivy, Semgrep all GitHub-native

## Alternatives considered

| Choice         | Alternative            | Why rejected                                                                 |
| -------------- | ---------------------- | ---------------------------------------------------------------------------- |
| NestJS         | Express                | Too unstructured at scale; AI codegen drifts without opinionated conventions |
| NestJS         | Fastify                | Better perf but less structure; perf irrelevant at MVP scale                 |
| Prisma         | Drizzle                | Less AI training data; manual migrations                                     |
| Prisma         | TypeORM                | Worse TypeScript ergonomics; decorator collision with NestJS                 |
| Prisma         | Raw SQL + Knex         | More verbose, less type safety, manual migrations                            |
| pgvector       | Pinecone / Weaviate    | Separate vendor, more infra; pgvector is sufficient at our scale             |
| Flutter        | React Native           | Flutter has better single-codebase story for both stores                     |
| Riverpod       | Bloc                   | More boilerplate; Riverpod async pattern is cleaner                          |
| Next.js        | Remix / SvelteKit      | Next.js has the deepest ecosystem and shadcn/ui support                      |
| Custom auth    | Auth0 / Clerk          | Vendor lock + AU data residency complexity                                   |
| Azure          | AWS / GCP              | Client preference; switching would burn 60–100 hours of migration            |
| GitHub Actions | Azure DevOps Pipelines | Less portable, weaker Flutter/Docker story                                   |

## Consequences

**Positive:**

- Single repo means cross-surface refactors are atomic
- Strict types end-to-end (Prisma → NestJS → packages/types → admin/web)
- AI codegen quality high due to opinionated frameworks
- Standard production patterns the auditor will recognise

**Negative:**

- Monorepo tooling has its own learning curve (Turborepo cache, pnpm workspace protocol)
- Cross-app dependency cycles are a real risk (mitigate via lint rules)
- Flutter sits outside pnpm; means two dependency systems
- Azure-specific services (App Insights, Content Safety) create some lock-in (mitigated via abstraction layer)

## References

- `PROJECT_CONTEXT.md` — full architecture context
