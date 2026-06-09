-- Postgres 15+ doesn't grant the superuser ownership of the `public` schema by default
-- in databases created via POSTGRES_DB. Prisma's `migrate dev` needs schema ownership
-- to create the shadow database. This grants what's needed on first container init.
--
-- Runs ONLY on first container startup (Postgres entrypoint behavior — files in
-- /docker-entrypoint-initdb.d/ are executed against $POSTGRES_DB only when the
-- data dir is empty).

GRANT ALL ON SCHEMA public TO jobbees;
ALTER SCHEMA public OWNER TO jobbees;
GRANT ALL ON DATABASE jobbees TO jobbees;
