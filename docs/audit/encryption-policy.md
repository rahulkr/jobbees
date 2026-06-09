# Encryption Policy

**Last reviewed:** TODO
**Owner:** TODO (Dev)

## Encryption at rest

| Data store | Encryption |
| --- | --- |
| Azure Database for PostgreSQL | Azure Storage Service Encryption (256-bit AES) — Azure-managed keys |
| Azure Cache for Redis | TLS in transit + at-rest encryption on persistent storage |
| Azure Blob Storage | Storage Service Encryption (256-bit AES) — Azure-managed keys |
| Azure Key Vault | HSM-backed encryption for secrets, certificates |
| Local dev DB (Docker) | Not encrypted — local dev only, no production data |

## Encryption in transit

| Connection | Protocol |
| --- | --- |
| Mobile → API | HTTPS (TLS 1.2+) |
| Admin/Web → API | HTTPS (TLS 1.2+) |
| API → Postgres | TLS 1.2+ |
| API → Redis | TLS 1.2+ |
| API → Stripe / Gemini / Anthropic / OpenAI / Twilio / SendGrid | HTTPS (TLS 1.3 where supported) |
| API → Azure Blob | HTTPS |
| App Service → external | All outbound HTTPS |

## Application-level encryption

- **Passwords:** bcrypt with cost factor 12
- **JWT secrets:** stored in Azure Key Vault, rotated quarterly
- **Refresh tokens:** stored hashed in DB; rotated on every use
- **OAuth tokens (Google, Apple):** server-side only, never exposed to client

## Secrets management

- **Local development:** `.env.local` (gitignored)
- **Staging + production:** Azure Key Vault → App Service environment variables at boot
- **Never:** secrets in code, in CI logs, in chat with LLMs, in `.env` files committed to git

## Key rotation policy

| Secret | Rotation cadence | Method |
| --- | --- | --- |
| Stripe webhook signing secret | Annually or on incident | Stripe Dashboard → update Key Vault |
| JWT signing secret | Quarterly | Generate new → deploy → invalidate old refresh tokens |
| LLM API keys | Annually or on incident | Provider dashboard → update Key Vault |
| DB password | Annually | Azure portal → update Key Vault |
| Azure Storage account keys | Annually | Azure portal → update Key Vault |

## See also

- `access-control-policy.md`
- `incident-response-plan.md`
