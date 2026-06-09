# Local development Docker Compose

Starts Postgres (with pgvector) + Redis for local development.

## Usage

```bash
# From repo root
pnpm docker:up      # start
pnpm docker:down    # stop
pnpm docker:logs    # follow logs

# Reset (nuke data volumes)
pnpm docker:down
docker volume rm jobbees_postgres_data jobbees_redis_data
```

## What's running

| Service                | Port | Notes                                                 |
| ---------------------- | ---- | ----------------------------------------------------- |
| Postgres 16 + pgvector | 5432 | User: `jobbees` / Password: `jobbees` / DB: `jobbees` |
| Redis 7                | 6379 | No auth (local dev only)                              |

## Connecting

```
DATABASE_URL=postgresql://jobbees:jobbees@localhost:5432/jobbees?schema=public
REDIS_URL=redis://localhost:6379
```

These are already set in `.env.example` — copy to `.env.local` and you're good.

## GUI access

- **Prisma Studio:** `pnpm db:studio` (opens browser GUI)
- **TablePlus / DBeaver / pgAdmin:** connect with the credentials above
- **redis-cli:** `docker exec -it jobbees-redis redis-cli`

## pgvector verification

After containers start, verify the extension is available:

```bash
docker exec -it jobbees-postgres psql -U jobbees -d jobbees -c "CREATE EXTENSION IF NOT EXISTS vector;"
docker exec -it jobbees-postgres psql -U jobbees -d jobbees -c "SELECT extname FROM pg_extension WHERE extname = 'vector';"
```

The first Prisma migration (`000_enable_pgvector`) does this automatically when you run `pnpm db:migrate:dev`.

## Production note

This is **local dev only**. Production uses Azure Database for PostgreSQL Flexible Server and Azure Cache for Redis. See `ops/terraform/` for the production infrastructure-as-code (post-MVP).
