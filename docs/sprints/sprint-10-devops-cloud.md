# Sprint 10 — DevOps + Cloud deploy + WAF

**Dates:** Mon 26 Oct → Fri 6 Nov 2026 (10 working days)
**Theme:** Move from "works on my Mac with Docker" to "works on Azure with Cloudflare WAF, private endpoints, CI/CD, Key Vault, App Insights." Same code, real infrastructure, public URL.
**Hours budget:** ~105 (all infra / DevOps, ~5 backend swap to cloud SDKs; +16h per 14 Jun Estimation v1.2 verification; +14h per Estimation v1.2 audit — DEV-07 / DEV-08 / DEV-11)
**Mid-sprint demo:** Fri 30 Oct
**End-of-sprint demo:** Fri 6 Nov

**⚠️ First sprint with real cloud spend.** Budget ~$300-400/mo Azure + $25/mo Cloudflare from this sprint onwards. Track in PROJECT_CONTEXT.md.

## Goal in one sentence

By Friday 30 Oct, the same demo flows we've been doing on localhost (client posts job → tasker makes an offer → payment → completion → tax invoice → dispute) all work against a public URL `api.jobbees.com.au` behind Cloudflare WAF, with Postgres + Redis + Blob + Key Vault on private endpoints (no public IPs), and every PR auto-deploys to a staging environment.

## Scope — inventory rows

### Backend cloud swap

| ID      | Item                                                             | Call | Hrs | Notes                                         |
| ------- | ---------------------------------------------------------------- | ---- | --- | --------------------------------------------- |
| Storage | Swap local FS → Azure Blob SDK                                   | n/a  | 4   | Wrap in adapter; no business-logic changes    |
| Secrets | Swap `.env` reads → ConfigService backed by Key Vault references | n/a  | 3   | Already using ConfigService — flip the source |

### DevOps / Infra

| ID     | Item                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | Call    | Hrs | Notes                                                                                                       |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | --- | ----------------------------------------------------------------------------------------------------------- |
| 403    | Environment management (dev/staging/prod)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | IN      | 4   | Terraform workspaces or env-suffixed naming                                                                 |
| 404    | Database migrations (Prisma)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | IN      | 3   | Already implemented; wire to CI                                                                             |
| 405    | CI/CD basic (lint, test, deploy on main)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | THIN→IN | 8   | Promote to IN — needs to be in place for ongoing dev                                                        |
| 406    | PaaS deployment (Azure App Service)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | IN      | 4   | 3 App Service plans: api, admin, web                                                                        |
| 407    | Secrets management (Key Vault)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | IN      | 3   |                                                                                                             |
| 408    | SSL / TLS                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | IN      | 1   | Cloudflare-managed or App Service-managed                                                                   |
| 409    | Backups (Azure auto-only)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | THIN    | 2   | Built into Azure Postgres Flexible                                                                          |
| 413    | Status page                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | THIN    | 2   | Simple status.jobbees.com.au — static hosted                                                                |
| 414    | API versioning                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | THIN    | 1   | `/v1/...` prefix on all routes                                                                              |
| 415    | OpenAPI docs                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | THIN    | 3   | NestJS Swagger module — auto-generated                                                                      |
| 416    | Health check endpoints                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | IN      | 2   | `/health` (liveness) + `/ready` (readiness)                                                                 |
| 417    | Encryption at rest                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | IN      | 1   | Azure-managed (AES-256 default)                                                                             |
| 418    | Encryption in transit                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | IN      | 1   | TLS 1.2+                                                                                                    |
| 419    | Secret rotation policy                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | THIN    | 2   | Document in `docs/audit/encryption-policy.md`                                                               |
| DEV-09 | **Infrastructure as Code (Terraform — Azure resources)** (per 14 Jun Estimation v1.2 verification) — Terraform modules for all Azure resources: PostgreSQL Flexible Server, Redis Cache, Blob Storage (with lifecycle policies), App Service Plan + slots, Static Web Apps, Container Registry, Key Vault, Application Insights, Virtual Network + subnets. Environment promotion via Terraform workspaces (dev/staging/prod). State stored in Azure Blob backend with locking. Enables full environment rebuild from scratch for DR. | IN      | 14  | MDR §4.1. Brings IaC discipline before going live. Without it, env recreation is multi-day manual ClickOps. |
| DEV-13 | **Customer-managed keys (CMK) for sensitive document storage** (per 14 Jun Estimation v1.2 verification) — Azure Blob containers holding KYC documents (ID scans, selfies), TFN records, and PCC/WWCC uploads configured with customer-managed encryption keys via Azure Key Vault. CMK rotation policy (annual). Separate from standard Key Vault secret management.                                                                                                                                                                 | IN      | 2   | MDR §4.4. Privacy Act + ATO requirement for highest-sensitivity data classes.                               |
| DEV-07 | **SLA monitoring + alerting (99.9% target)** (per Estimation v1.2 audit) — Azure Monitor + Application Insights with explicit availability SLO (99.9% = 8.7h downtime/year). PagerDuty wired for critical alerts. Synthetic uptime checks every 60s on `/health` + key business endpoints. Burn-rate alerts on SLO budget.                                                                                                                                                                                                            | IN      | 4   | Sits on top of App Insights (covered in S10). Adds the formal SLO + alerting tier.                          |
| DEV-08 | **Log aggregation + structured logging + PII redaction** (per Estimation v1.2 audit) — structured JSON logging across API + admin + worker pool, shipped to Azure Log Analytics. `pino.redact` configured to strip email/phone/TFN/license number/bank info before transmission (Privacy Act requirement — launch blocker). 90d hot retention + 1yr cold archive.                                                                                                                                                                     | IN      | 4   | Already partially covered by pino in code; this row formalises the aggregation pipeline + retention policy. |
| DEV-11 | **Compute topology — BullMQ worker pool + scaling + sticky sessions** (per Estimation v1.2 audit) — separate Azure App Service for BullMQ workers (job processing isolated from API traffic — prevents queue saturation starving API responses). Horizontal scaling rules for both API + worker plans (CPU/memory thresholds). Application Gateway sticky sessions for Socket.IO (required for real-time messaging across multi-instance deployments).                                                                                | IN      | 6   | MDR §4.3. Configured via DEV-09 Terraform modules.                                                          |

### Cloudflare WAF (or Azure Front Door — per ADR 007)

| ID   | Item                                                                   | Hrs | Notes                             |
| ---- | ---------------------------------------------------------------------- | --- | --------------------------------- |
| Edge | Stand up Cloudflare zone for jobbees.com.au                            | 2   | DNS migration if needed           |
| Edge | Enable OWASP CRS managed rules                                         | 1   |                                   |
| Edge | Bot Fight Mode                                                         | 1   |                                   |
| Edge | Custom rules: geo-restrict admin (AU only), rate limit auth/payment/AI | 3   | Per `docs/audit/edge-security.md` |
| Edge | App Service inbound IP-allowlist Cloudflare IPs                        | 2   |                                   |
| Edge | Tune detection mode → prevention mode after 3-day baseline             | 2   |                                   |

### Azure network segmentation

|                                     | Hrs | Notes                             |
| ----------------------------------- | --- | --------------------------------- |
| VNet + subnets                      | 3   | Per `docs/audit/edge-security.md` |
| Private endpoint: Postgres Flexible | 2   | No public IP                      |
| Private endpoint: Redis Cache       | 2   |                                   |
| Private endpoint: Blob Storage      | 2   |                                   |
| Private endpoint: Key Vault         | 2   |                                   |
| NSG rules                           | 2   |                                   |

### Admin config endpoints

| ID  | Item                                   | Hrs | Notes                                    |
| --- | -------------------------------------- | --- | ---------------------------------------- |
| 501 | Stripe credentials display (read-only) | 1   | Wire to Key Vault                        |
| 502 | LLM provider config + model selection  | 2   | Read-only at MVP, runtime tweak post-MVP |
| 503 | Feature flags (env-based booleans)     | 2   |                                          |
| 504 | Maintenance mode toggle                | 1   |                                          |

**Sprint total: ~106h** (was 76h; +16h per 14 Jun Estimation v1.2 verification (DEV-09 +14, DEV-13 +2); +14h per Estimation v1.2 audit — DEV-07 SLA monitoring +4, DEV-08 log aggregation +4, DEV-11 compute topology +6)

## Decision gate — Day 1

**Edge security vendor.** Default per `docs/audit/edge-security.md`: **Cloudflare Pro** ($25/mo, $300/yr). Alternative: Azure Front Door Premium ($335/mo, $4,020/yr).

Recorded in `docs/adrs/007-edge-security.md` Day 1.

## Schema additions

None (Sprint 10 doesn't add features — it deploys what exists).

## Definition of done

Same as Sprint 1, plus per `docs/audit/security-by-stage.md`:

- [ ] All 4 data stores (Postgres, Redis, Blob, Key Vault) have NO public IP — only private endpoint
- [ ] App Service accepts traffic ONLY from Cloudflare IPs (verified by curl-against-direct-URL → 403)
- [ ] All secrets read via Key Vault references in App Service config — no `.env` files on prod
- [ ] WAF in Prevention mode catches: SQLi (sqlmap test), XSS (xsstrike test), bot traffic (Bot Fight Mode hit log)
- [ ] DDoS test fires mitigation visibly (1000 req/s from one IP → blocked at edge)
- [ ] `/admin/*` returns 403 from non-AU IPs (test with VPN)
- [ ] CI auto-deploys to staging on merge to `main`
- [ ] Manual promotion to prod after smoke test
- [ ] `prisma migrate deploy` runs only in CI, not on app startup (CLAUDE.md rule 12)
- [ ] Backup test: trigger restore from yesterday's automatic Postgres backup

## Friday demo script (end-of-sprint Fri 30 Oct)

5 min — same demo as Sprint 6 (or any prior), but against the public URL:

```
00:00 — "Sprint 10 wrap. Same flows you've seen before — now on Azure."
00:15 — Show app.jobbees.com.au resolving. Show DNS at Cloudflare.
00:30 — Demo a previously-recorded flow (e.g., Sprint 6 job completion
        with tax invoice) — but the app is hitting api.jobbees.com.au,
        not localhost. Network tab shows real domain.
01:00 — Show Cloudflare dashboard: live traffic, WAF events, bot block
        count.
01:20 — Curl directly to App Service URL → 403 (Cloudflare-only).
01:35 — Curl to /admin/* from non-AU IP (VPN) → 403 (geo-restricted).
01:50 — Trigger 200 concurrent requests to /auth/login → rate limit
        fires at 30, returns 429.
02:10 — SQL injection test: `'OR 1=1--` in a field → WAF blocks at edge.
02:25 — Show Azure Portal: App Service running, Postgres Flexible
        with private endpoint, Key Vault references in app config, Blob
        storage with private endpoint.
02:50 — Show App Insights: live metrics, error rate, latency P50/P95.
03:10 — Show GitHub Actions: PR merged → CI runs → deploys to staging
        → smoke tests pass → manual approval gate → prod deploy.
03:30 — Show OpenAPI docs at /docs.
03:45 — Show status page at status.jobbees.com.au.
04:00 — Cost dashboard: month-to-date Azure + Cloudflare. Project
        October cost.
04:15 — Coverage report. Stoplight + asks. End.
```

## Risks

| Risk                                               | Likelihood | Impact | Mitigation                                                                                                     |
| -------------------------------------------------- | ---------- | ------ | -------------------------------------------------------------------------------------------------------------- |
| First Azure deploy reveals env-config bugs         | High       | High   | Stage Mon-Tue, troubleshoot Wed-Thu, demo Fri. Buffer in S11.                                                  |
| Cost overrun (forgot to right-size App Service)    | Medium     | Medium | Start at Basic B1 tier (~$13/mo); scale up only when needed                                                    |
| WAF false positives block legitimate requests      | High       | Low    | Detection mode for 3 days before prevention; tune custom rules                                                 |
| Cloudflare IP-allowlist rotates → app inaccessible | Medium     | High   | Cloudflare publishes IPs; cron job updates App Service NSG monthly OR use Cloudflare Tunnel (zero IP exposure) |
| Postgres connection pool exhaustion under load     | Medium     | Medium | PgBouncer in front; default pool size 50                                                                       |
| Key Vault rate limits during cold-start            | Low        | Medium | Cache resolved secrets in app memory; refresh hourly                                                           |
| Stripe webhook URL changes mid-sprint              | Low        | Medium | Update via Stripe Dashboard; document in runbook                                                               |
| DNS migration breaks email (MX records)            | Low        | High   | Pre-stage all DNS records before flipping; backup current records                                              |

## Explicitly NOT in scope

- 99.9% availability SLO + multi-AZ — POST (inventory row 412; accepted 99.5% at MVP)
- DR drill (quarterly) — POST (inventory row 410)
- Load testing (k6) — POST (inventory row 411; do during Sprint 12 soft-launch if time)
- Redis adapter for Socket.IO multi-node — POST (inventory row 275; single-node holds at MVP scale)
- Azure Front Door Premium — only if ADR 007 picks it; default is Cloudflare Pro
- Multiple environments beyond staging + prod — single staging at MVP

## Day-by-day rough plan

| Day          | Task                                                                                                               |
| ------------ | ------------------------------------------------------------------------------------------------------------------ |
| Mon 19 (D1)  | ADR 007 (edge security vendor). Terraform skeleton (modules: vnet, app-service, postgres, redis, blob, key-vault). |
| Tue 20 (D2)  | Terraform apply: vnet + Postgres Flexible + Redis + Blob + Key Vault (private endpoints). App Service plans.       |
| Wed 21 (D3)  | Backend: storage adapter (local FS → Azure Blob SDK). Secrets to Key Vault references. Deploy first staging build. |
| Thu 22 (D4)  | CI/CD pipeline (GitHub Actions): lint/test/typecheck/Semgrep/build/deploy-to-staging on push.                      |
| Fri 23 (D5)  | Mid-sprint demo + catch-up. Cloudflare zone + DNS migration. WAF detection mode on.                                |
| Mon 26 (D6)  | App Service inbound IP-allowlist Cloudflare. Health/ready endpoints. OpenAPI docs.                                 |
| Tue 27 (D7)  | WAF custom rules (geo-restrict admin, rate limits, OWASP CRS tuning). 3-day detection-mode baseline begins.        |
| Wed 28 (D8)  | API versioning (`/v1` prefix). Status page (static). Secret rotation policy docs. Backup test.                     |
| Thu 29 (D9)  | WAF detection → prevention mode. Final smoke tests. Cost projection.                                               |
| Fri 30 (D10) | End-of-sprint demo + CSV update. Tag `sprint-10-end`.                                                              |

## Definition of "shippable"

- [ ] All 4 demo flows from prior sprints run against api.jobbees.com.au
- [ ] No public IP on Postgres/Redis/Blob/Key Vault (verified via Azure Portal)
- [ ] App Service direct URL returns 403 (verified curl)
- [ ] WAF in Prevention mode, no critical false positives in last 24h
- [ ] CI deploys to staging on every PR merge
- [ ] Manual prod promotion gated by environment approval
- [ ] Monthly cost projection within budget (~$325-425/mo)
- [ ] `./scripts/coverage.sh` reports ~97% MVP
- [ ] Sprint 11 detail doc reviewed
- [ ] Apple Developer Program enrolled, App Store Connect set up (required for S11 TestFlight)

## Expected PRs (~12-15)

- `chore(adrs): 007 edge security vendor (Cloudflare Pro)`
- `feat(infra): Terraform modules — vnet + private endpoints`
- `feat(infra): Terraform — Postgres Flexible + Redis + Blob + Key Vault`
- `feat(infra): Terraform — App Service plans (3 apps)`
- `feat(api/infra): storage adapter (Azure Blob SDK)`
- `feat(api/config): Key Vault references via ConfigService`
- `feat(api): health + ready endpoints`
- `feat(api): OpenAPI / Swagger docs`
- `feat(api): API versioning (/v1 prefix)`
- `feat(ci): GitHub Actions — lint/test/typecheck/Semgrep + deploy-staging`
- `feat(ci): CI — prod deploy with manual approval gate`
- `feat(infra): Cloudflare zone + WAF + rate limits + geo-restrict admin`
- `feat(infra): App Service inbound IP-allowlist Cloudflare`
- `feat(admin/config): Stripe key display + LLM model selection + feature flags + maintenance mode`
- `docs(audit): backup test results, secret rotation policy, edge security final config`
