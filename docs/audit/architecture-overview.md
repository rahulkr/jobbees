# Architecture Overview

**Last reviewed:** TODO (date)
**Owner:** TODO (name + role)

## System diagram

TODO: insert architecture diagram (PNG / SVG) showing:
- Mobile clients (iOS + Android)
- Admin web client
- Public web client
- NestJS API
- PostgreSQL + pgvector
- Redis
- Azure Blob Storage
- Stripe (PaymentIntent, Connect, Identity)
- Gemini + Claude + OpenAI APIs
- Twilio / SendGrid / FCM / APNS
- Azure Content Safety
- Sentry + Azure App Insights

## Components

### Client layer
- **Mobile** (Flutter, iOS + Android) — user-facing app
- **Admin** (Next.js) — internal operations
- **Web** (Next.js) — public marketing + SEO

### Application layer
- **NestJS API** (Node.js + TypeScript) — single source of truth for business logic, exposed over HTTPS REST + Socket.IO

### Data layer
- **PostgreSQL 16** (Azure Database for PostgreSQL Flexible Server) with pgvector extension
- **Redis** (Azure Cache for Redis) — sessions, rate limits, idempotency, BullMQ job queue
- **Azure Blob Storage** — user uploads, completion proof photos, generated PDFs

### Integration layer
- **Stripe** — payments, Connect Express (tasker payouts), Identity (KYC)
- **Google Gemini** — task extraction, chat policing, support agent, budget nudge
- **Anthropic Claude** — dispute mediator, admin co-pilot
- **OpenAI** — embedding generation
- **Twilio** — SMS (OTP, critical alerts)
- **SendGrid** — transactional email
- **FCM / APNS** — push notifications
- **Azure Content Safety** — image moderation

### Observability layer
- **Sentry** — error tracking
- **Azure Application Insights** — application logs, performance, request tracing

## Data flow at a glance

1. Mobile user posts a task → POST `/tasks` on NestJS API → Postgres write + embedding job enqueued
2. Embedding worker reads task → OpenAI embedding API → updates Postgres
3. Matching service finds top-K taskers via pgvector cosine similarity + ranked feed weights
4. Push notification triggers to matched taskers via FCM/APNS
5. Tasker bids → REST API → Postgres write → notification to poster
6. Poster accepts → Stripe PaymentIntent authorisation → escrow

See `data-flow-diagram.md` for payment + KYC detail.

## Deployment topology

- All three TS apps on Azure App Service (Linux containers)
- Postgres + Redis on Azure managed services
- Region: Australia East (primary)
- TODO: confirm DR region (Australia Southeast)

## Network architecture

- All traffic HTTPS (TLS 1.2+ at edge, terminates at Azure Front Door)
- **Public internet → Azure Front Door Premium** (WAF policy attached — OWASP Top 10, bot manager, custom rate-limit rules, geo-restriction on admin paths). See `docs/audit/edge-security.md`.
- **Front Door → App Service**: backend traffic over Microsoft backbone; App Service inbound restricted to Front Door service tag (no direct internet access)
- **App Service → Postgres**: private endpoint within VNet, no public IP on the database
- **App Service → Redis**: private endpoint within VNet, no public IP on the cache
- **App Service → Azure Blob / Key Vault**: private endpoint within VNet
- **App Service → Stripe / Gemini / etc.**: outbound HTTPS to public endpoints (no inbound from these)
- DDoS protection: Azure DDoS Basic (included with Front Door). Standard tier deferred until traffic justifies the spend.

## Edge security controls

See `docs/audit/edge-security.md` for the full WAF policy, custom rules, and exception process. Summary:

| Control | What it does |
| --- | --- |
| **Azure WAF managed rules** (Microsoft Default Rule Set 2.1) | Blocks OWASP Top 10 attacks at the edge before they hit NestJS |
| **Bot Manager rule set** | Catches scrapers, vulnerability scanners |
| **Custom rule: admin geo-restriction** | `/admin/*` only accessible from AU IPs |
| **Custom rule: auth rate limit** | 30 req/min per IP on `/auth/*` (brute-force protection) |
| **Custom rule: payment rate limit** | 60 req/min per IP on `/payment/*` |
| **VNet + private endpoints** | Postgres / Redis / Blob have no public IPs, only reachable via App Service in the VNet |
| **App Service inbound restriction** | Accepts traffic only from Front Door service tag (`AzureFrontDoor.Backend`) |

## See also

- `PROJECT_CONTEXT.md` §3 Tech Stack
- `PROJECT_CONTEXT.md` §5 The Four Surfaces
- ADR-001 Monorepo and Stack Choices
