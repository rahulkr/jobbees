# ADR-007: Edge security — WAF + DDoS + sender ID

**Status:** Accepted
**Date:** 2026-06-09
**Decider:** Engineering lead
**Supersedes:** none

## Context

JOBBees needs an edge security layer between the public internet and Azure App Service to provide:

- Web Application Firewall (WAF) — block SQL injection, XSS, OWASP attacks
- DDoS protection — absorb large-volume traffic attacks
- Bot mitigation — block scrapers + credential-stuffing
- Geo-restriction — limit admin to AU only
- Rate limiting at edge — protect `/auth/*`, `/payment/*`, `/ai/*` from abuse
- TLS termination — managed certificates

Three viable vendor options were evaluated.

## Options considered

### Option A — Cloudflare Pro

- $20/mo billed annually ($240/year) or $25/mo monthly
- Flat fee, no traffic charges
- 2 managed rule sets: OWASP Core Rule Set + Cloudflare Managed Ruleset
- 20+ custom firewall rules
- Bot Fight Mode (rule-based)
- Unmetered DDoS at L3/L4/L7
- ~300+ PoPs globally, 5+ AU PoPs (Sydney, Melbourne, Perth, Brisbane, Adelaide)
- Image optimization included
- Cloud-portable (works against any backend)

### Option B — Azure Front Door Standard

- ~$22 base + traffic + WAF rules → ~$35-50/mo at MVP scale
- Microsoft Default Rule Set 1.x (older than 2.1 which is Premium-only)
- 5 custom rules on Standard tier
- Basic DDoS only (advanced needs Azure DDoS Standard at +$2,944/mo)
- ~75 PoPs globally, 2 AU PoPs
- Native Azure integration (WAF logs into App Insights)
- Single-vendor billing with Azure
- Locks into Azure as cloud

### Option C — Azure Front Door Premium

- ~$330+/mo base, traffic included
- Microsoft Default Rule Set 2.1 (latest)
- Bot Manager (ML-based)
- Private link to App Service (zero public IP on App Service backend)
- Highest posture but enterprise-priced
- Native Azure integration

## Decision

**Cloudflare Pro** (Option A) at $20/mo billed annually ($240/year).

For staging environments during Sprint 10+, use **Cloudflare Free** ($0).

## Rationale

| Dimension               | Why Cloudflare Pro wins                                                  |
| ----------------------- | ------------------------------------------------------------------------ |
| **Cost**                | $240/year vs ~$500/year (Azure Standard) vs ~$4,000/year (Azure Premium) |
| **WAF quality**         | 2 managed rule sets vs 1 (older) on Azure Standard                       |
| **Custom rules**        | 20+ vs 5 on Azure Standard                                               |
| **DDoS**                | Unmetered + industry-leading; Azure Standard is basic                    |
| **Geographic**          | 4× more PoPs globally, 2.5× more AU PoPs                                 |
| **Cost predictability** | Flat fee; Azure has per-GB traffic charges                               |
| **Portability**         | Cloud-agnostic; Azure locks into Azure                                   |

Azure Front Door Premium would be the right choice if:

- Single-vendor procurement / billing was a hard requirement, OR
- "Zero public IPs on backends" was an audit requirement (private link)

Neither applies to JOBBees at MVP.

## Trade-offs accepted

- WAF logs live in the Cloudflare dashboard rather than Azure App Insights → one extra console for security event review
- App Service backend has a public IP — restricted to Cloudflare's published IP ranges via inbound IP allowlist (refreshed monthly via cron)
- Separate vendor billing relationship (Cloudflare account + Azure account)

## Upgrade path (post-MVP)

If we ever grow into needing:

- ML-based bot management (vs rule-based Bot Fight Mode)
- True zero-public-IP backend posture
- WAF logs natively in App Insights

…migrate to Azure Front Door Premium in year 2. Migration is straightforward: both speak HTTPS to App Service, both terminate TLS, both attach a WAF policy.

## Implementation (Sprint 10)

Per `docs/audit/edge-security.md`:

1. Stand up Cloudflare zone for `jobbees.com.au` covering `api.`, `admin.`, `www.`, `jobbees.com.au` (apex)
2. Enable OWASP Core Rule Set in **Detection mode** for 5-7 days
3. Tune false positives in detection logs
4. Flip to **Prevention mode**
5. Configure custom rules:
   - Rate limit `/v1/auth/*` to 30 req/min per IP
   - Rate limit `/v1/payment/*` to 60 req/min per IP
   - Rate limit `/v1/ai/*` to 60 req/min per user (header inspection)
   - Geo-restrict `admin.jobbees.com.au` to AU only
6. Configure App Service inbound IP allowlist for Cloudflare ranges
7. Verify direct App Service URL returns 403 (Cloudflare-only access)

## Acceptance criteria

- [ ] All 4 domains (`api.`, `admin.`, `www.`, apex) proxied through Cloudflare Pro
- [ ] WAF blocks SQLi payload in test (`sqlmap` against staging)
- [ ] WAF blocks XSS payload in test (`xsstrike` against staging)
- [ ] `/admin/*` returns 403 from non-AU VPN
- [ ] Rate limit fires on > 30 auth attempts/min from same IP
- [ ] Direct App Service URL returns 403
- [ ] WAF blocks logged + queryable in Cloudflare dashboard
- [ ] Cost dashboard shows $20/mo flat (no traffic surprises)

## References

- Cloudflare pricing (verified 2026-06-09): https://www.cloudflare.com/plans/
- Azure Front Door pricing: https://azure.microsoft.com/en-us/pricing/details/frontdoor/
- `docs/audit/edge-security.md` (detailed implementation plan)
- `docs/sprints/sprint-10-devops-cloud.md`
