# Edge Security — WAF + DDoS + Network Segmentation

**Last reviewed:** TODO
**Owner:** TODO (Dev)
**Status:** Design spec. Vendor choice pending client decision. Implementation lands in Phase 4 (Launch Hardening) via Terraform.

This is the runtime security layer that sits between the public internet and the API. It complements the code-time scanners (CodeQL, Semgrep, Trivy) and the application-layer controls (idempotency, rate limits in NestJS).

The original architect review didn't explicitly call out edge security as a category. For a payment-handling Australian marketplace, WAF + DDoS + network segmentation are non-negotiable for the IT audit. **Two viable vendor choices** — client decides per `## Decision framework` below.

## Architecture (vendor-agnostic view)

```
Internet
   ↓
[Edge layer: WAF + DDoS + caching + TLS termination]    ← Cloudflare Pro OR Azure Front Door Premium
   ↓
Azure App Service (api, admin, web)                       ← in VNet, restricted inbound
   ↓
Postgres + Redis + Blob + Key Vault (private endpoints, no public IPs)
```

Three subdomains:

- `api.jobbees.com.au` → NestJS API
- `admin.jobbees.com.au` → Next.js admin
- `jobbees.com.au` + `www` → Next.js public web

## Option A — Cloudflare Pro (recommended for MVP)

### What you get

- Cloudflare-managed WAF with OWASP Core Rule Set
- Bot Fight Mode (catches scrapers, vulnerability scanners — rule-based, not ML)
- DDoS protection at L3/L4/L7 (Cloudflare's anycast network — protects ~20% of all web traffic globally)
- Free automatic SSL certificates (Universal SSL)
- Global anycast network (~300+ PoPs, including AU)
- Custom firewall rules (rate limit, geo-restriction, IP allowlist)
- Per-zone (per-domain) pricing
- 24/7 chat support

### Cost

- **$25/month per zone** (`jobbees.com.au` is one zone covering all subdomains)
- **$0 bandwidth fees** (Cloudflare absorbs egress to end users)
- **Total: ~$25/month**

### Trade-offs vs Azure Front Door Premium

| Aspect                      | Cloudflare Pro                                                                                           |
| --------------------------- | -------------------------------------------------------------------------------------------------------- |
| WAF managed rules           | ✅ OWASP Core Rule Set                                                                                   |
| Bot blocking                | ✅ Bot Fight Mode (rule-based) — less sophisticated than Azure's ML model but catches common bots        |
| DDoS protection             | ✅ Industry-leading; Cloudflare absorbs massive attacks routinely                                        |
| Rate limiting at edge       | ✅ Per-rule, basic                                                                                       |
| TLS termination + cert mgmt | ✅ Automatic                                                                                             |
| Logs delivery               | Cloudflare dashboard (export to S3/cloud storage on Business+ plan) — **not native in App Insights**     |
| Private link to App Service | ❌ **App Service needs a public IP**, locked down via inbound IP allowlist of Cloudflare's published IPs |
| Cross-cloud portable        | ✅ Works with any backend (Azure, AWS, GCP)                                                              |
| Vendor relationship         | New (Cloudflare account, billing, support)                                                               |

### Why "App Service still has a public IP" is OK at MVP

The standard hardening is: configure App Service to **only accept inbound traffic from Cloudflare's IP ranges** (Cloudflare publishes them and refreshes monthly). Practically:

- Direct access to the App Service URL from the public internet returns 403
- All real traffic flows: user → Cloudflare → App Service → response
- The public IP is technically present but unreachable from anywhere except Cloudflare

This is the same model used by most production Cloudflare-fronted apps. **It's defensible at the IT audit** — auditors are familiar with this pattern.

The only thing it doesn't give you: the "zero public IPs anywhere" posture that some hyper-regulated industries (banking, defence) require. JOBBees is a consumer marketplace, not regulated banking.

### Custom rule plan

| #   | Rule                                                       | Action               | Notes                                 |
| --- | ---------------------------------------------------------- | -------------------- | ------------------------------------- |
| 1   | OWASP Core Rule Set                                        | Block                | Managed; tune sensitivity per traffic |
| 2   | Bot Fight Mode                                             | Block known bad bots | Enable in Cloudflare dashboard        |
| 3   | Geo-restrict `admin.jobbees.com.au` to AU                  | Block non-AU         | Custom firewall rule                  |
| 4   | Rate limit `/auth/*` to 30 req/min per IP                  | Block over limit     | Cloudflare Rate Limiting feature      |
| 5   | Rate limit `/payment/*` to 60 req/min per IP               | Block over limit     | Same                                  |
| 6   | Rate limit `/ai/*` to 60 req/min per user (via auth token) | Block over limit     | Custom rule with header inspection    |

---

## Option B — Azure Front Door Premium + WAF policy

### What you get

- Microsoft-managed WAF Default Rule Set 2.1 (OWASP-aligned + Microsoft additions)
- Bot Manager Rule Set 1.0 (ML-based — more sophisticated than Cloudflare's rule-based)
- Private link to App Service backends (zero public IPs on origin — strongest posture)
- DDoS Basic protection (L3/L4 volumetric, included)
- Global anycast network (~75 PoPs)
- TLS termination
- Native integration with App Insights (WAF logs flow into your existing observability)
- Single-vendor billing with Azure
- Granular custom rules including per-user-token rate limits

### Cost

- **~$330/month base** (Front Door Premium)
- **~$0.06/GB** outbound data transfer (at MVP ~50 GB/month = ~$3)
- **DDoS Standard** (optional, advanced) = $2,900/month — **defer at MVP**
- **Total: ~$335/month**

### Why "Premium" specifically

The Standard tier of Azure Front Door (~$50/month with WAF) is cheaper but doesn't include:

- Bot Manager (only available on Premium)
- Private link to backend (only Premium)
- Microsoft Default Rule Set 2.1 (Standard is on older v1.1)

If we go Azure, Premium is the right choice. Standard is in between two viable options without clearly winning either.

### Custom rule plan

| #   | Rule                                         | Action                |
| --- | -------------------------------------------- | --------------------- |
| 100 | Geo-restrict `/admin/*` paths to AU only     | Block if country ≠ AU |
| 200 | Geo-restrict sanctioned countries            | Block                 |
| 300 | Rate limit `/auth/*` to 30 req/min per IP    | Block over limit      |
| 400 | Rate limit `/payment/*` to 60 req/min per IP | Block over limit      |
| 500 | Rate limit `/ai/*` to 60 req/min per user    | Block over limit      |
| 600 | Block known TOR exit nodes (managed list)    | Block                 |

---

## Common to both options — network segmentation

Independent of vendor choice, the backend network is locked down:

| Resource                              | Network               | Public IP                                                                                 |
| ------------------------------------- | --------------------- | ----------------------------------------------------------------------------------------- |
| Edge (Cloudflare or Azure Front Door) | Public (anycast)      | Yes (this is the front door)                                                              |
| Azure App Service (3 apps)            | VNet integrated       | Cloudflare option: yes, IP-restricted to Cloudflare. Front Door option: no (private link) |
| Azure Database for PostgreSQL         | VNet private endpoint | **No**                                                                                    |
| Azure Cache for Redis                 | VNet private endpoint | **No**                                                                                    |
| Azure Blob Storage                    | VNet private endpoint | **No**                                                                                    |
| Azure Key Vault                       | VNet private endpoint | **No**                                                                                    |

In both options, the data stores (Postgres, Redis, Blob, Key Vault) have **no public IPs**. The only difference is whether the App Service tier itself has a public IP (Cloudflare option) or not (Front Door option).

---

## Decision framework — to discuss with client

Bring the client these four questions:

### 1. Is Azure-only / single-vendor a hard requirement?

**If YES** → Azure Front Door Premium. Some clients have procurement, compliance, or vendor-management policies requiring everything in one cloud. Don't fight that.

**If NO / "we're flexible"** → Cloudflare Pro is the better default at MVP.

### 2. Does the IT audit require "zero public IPs on backends"?

Confirm with the auditor (or the audit framework being targeted — ISO 27001, SOC 2, ASD ISM, etc.):

**If YES** → Azure Front Door Premium (private link is the only way to achieve this).

**If NO / "IP-restriction is acceptable"** → Cloudflare Pro is fine. This is the typical answer for AU consumer marketplace platforms.

### 3. Is the $305/month cost difference meaningful?

- Cloudflare Pro: $25/month → $300/year
- Azure Front Door Premium: $335/month → $4,020/year
- Difference: **$3,720/year**

**If "yes, cost matters at this stage"** → Cloudflare Pro

**If "no, in-cloud convenience worth the spend"** → Azure Front Door Premium

### 4. Where do you want WAF / security logs to live?

**If "in App Insights with everything else"** → Azure Front Door Premium (native integration)

**If "OK to access Cloudflare's dashboard for security event review"** → Cloudflare Pro is fine. You can also export logs to Azure Storage via Cloudflare Logpush (paid feature on Business+ tier — not needed at MVP).

---

## Recommended default (if client says "you decide")

**Cloudflare Pro.** Reasoning:

1. **Industry-standard** for AU SaaS marketplaces at this scale
2. **$3,720/year cheaper** than Azure Premium, no meaningful loss of protection
3. **Cloud-portable** — preserves optionality if you ever move off Azure
4. **Easier to debug** — Cloudflare's dashboard is well-designed and you can see attacks in real-time
5. **Faster to set up** (~3 hours vs ~8 hours for Front Door + private link config)
6. **IP-restricted App Service** is defensible at AU IT audits for consumer marketplaces

**Upgrade path:** if you're successful and grow into needing ML-based bot management or zero-public-IP posture, migrate to Front Door Premium in year 2. Switching is straightforward — both speak HTTPS to App Service, both terminate TLS, both attach a WAF policy.

---

## Implementation order (vendor-agnostic)

1. **Phase 4 (Launch Hardening) — week 1:**
   - Stand up edge layer (Cloudflare zone OR Front Door profile)
   - Enable WAF in **Detection mode** (log only, don't block) for 5–7 days
2. **Phase 4 — week 2:**
   - Review detection logs, tune false positives
   - Flip WAF to **Prevention mode**
   - Add custom rules (geo-restrict admin, rate limits)
3. **Phase 4 — pre-launch:**
   - Add VNet + private endpoints for Postgres / Redis / Blob / Key Vault
   - Lock down App Service inbound (per vendor approach)
   - Verify backend is unreachable from arbitrary IPs
4. **First week of soft-launch:**
   - Daily review of blocked requests in WAF logs
   - Tune custom rules based on real traffic

## Acceptance criteria (both options)

- No public IP on Postgres, Redis, Blob, or Key Vault
- App Service accepts traffic only via the edge (Cloudflare IPs or Front Door service tag)
- WAF blocks SQLi/XSS payloads in test (`sqlmap`, `xsstrike` against staging)
- `/admin/*` returns 403 from any non-AU IP
- Rate limit fires on > 30 auth attempts/min from same IP
- All WAF blocks logged and queryable (App Insights for Front Door, Cloudflare dashboard for Cloudflare)
- A test attack (e.g., 1000 req/sec from a single IP) triggers DDoS mitigation visibly

## What this skill does NOT cover

- Application-level rate limiting (in NestJS, complementary to WAF — see `apps/api/src/common/rate-limit/`)
- API authentication (JWT, see `apps/api/src/modules/auth/`)
- Image content moderation (Azure Content Safety, see `apps/api/src/modules/trust/content-safety.service.ts`)
- LLM abuse / cost protection (see `.claude/skills/multimodal-extraction/SKILL.md` cost guardrails)

## References

- `docs/audit/architecture-overview.md` — system context
- `docs/audit/incident-response-plan.md` — what to do during a DDoS / breach
- `docs/audit/vulnerability-management.md` — runtime + scanning controls
- `docs/audit/encryption-policy.md` — TLS termination happens at edge
- `ops/terraform/modules/edge/` (when built) — edge layer + private endpoint resource definitions
