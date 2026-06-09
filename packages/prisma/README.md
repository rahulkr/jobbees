# @jobbees/prisma

Database schema and migrations for JOBBees. Used by `apps/api`.

## Schema

`schema.prisma` is the source of truth for the data model. See `PROJECT_CONTEXT.md` §9 for conventions:

- cuid2 string IDs (set in app code)
- Integer cents for money
- UTC timestamps; render in Australia/Sydney
- Soft delete on user-facing entities
- Manual FK indexes (Prisma doesn't auto-add)
- Vector columns via `Unsupported("vector(1536)")`

## Workflow

```bash
# Start Postgres locally (from repo root)
pnpm docker:up

# Apply pending migrations to local DB + regenerate Prisma client
pnpm db:migrate:dev

# Open Prisma Studio (DB GUI)
pnpm db:studio

# Seed local DB with test data
pnpm db:seed

# Reset local DB (dangerous — wipes data)
pnpm --filter @jobbees/prisma migrate:reset
```

## Migrations

- `prisma migrate dev --name <descriptive_name>` — creates a new migration from schema changes, applies it locally
- `prisma migrate deploy` — applies pending migrations in staging/prod (run only via CI)
- **Never edit a migration after it's merged to main.** Always write a new migration.
- **pgvector extension** is enabled in `migrations/000_enable_pgvector/` — must run before any vector column is added.

## Adding a new model

1. Edit `schema.prisma`
2. Run `pnpm db:migrate:dev --name add_<model_name>`
3. Inspect the generated SQL in `migrations/<timestamp>_add_<model_name>/migration.sql`
4. Commit both `schema.prisma` AND the migration folder

## Vector columns

Prisma can't generate vector queries. After defining `embedding Unsupported("vector(1536)")?`:

1. Add an HNSW index via a raw SQL migration
2. Query the column via `prisma.$queryRaw` with the `<=>` cosine distance operator

See `.claude/skills/pgvector-match/SKILL.md` for the full pattern.
