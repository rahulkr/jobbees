/**
 * Prisma 7 config — replaces the legacy `datasource.url` field in schema.prisma
 * and the `prisma` section in package.json. See the v7 migration notes:
 * https://prisma.io/docs/orm/prisma-schema/overview/datasources#environment-variables
 *
 * What lives here:
 *   - schema location (replaces package.json "prisma.schema")
 *   - seed command   (replaces package.json "prisma.seed")
 *   - datasource URL (replaces the `url = env("DATABASE_URL")` line in the schema)
 *
 * Where the connection URL comes from:
 *   .env.local at the monorepo root for real values (gitignored — never commit).
 *   .env at the monorepo root for defaults/CI-safe values.
 *   Plain shell env vars take precedence over both files.
 */
import path from 'node:path';
import { config as loadEnv } from 'dotenv';
import { defineConfig } from 'prisma/config';

// packages/prisma/ → repo root is two up.
const repoRoot = path.resolve(__dirname, '..', '..');

// Load both files; later calls do NOT override variables that already exist,
// so .env.local wins over .env, and a shell-exported var wins over both.
loadEnv({ path: path.join(repoRoot, '.env.local') });
loadEnv({ path: path.join(repoRoot, '.env') });

if (!process.env.DATABASE_URL) {
  throw new Error(
    'DATABASE_URL is not set. Copy .env.example to .env.local at the repo root ' +
      'and fill in DATABASE_URL, or export it in your shell.',
  );
}

export default defineConfig({
  schema: path.join(__dirname, 'schema.prisma'),
  migrations: {
    seed: 'tsx seed.ts',
  },
  datasource: {
    url: process.env.DATABASE_URL,
  },
});
