/**
 * ESLint config for @jobbees/prisma — uses the shared base.
 *
 * Why a per-workspace file: ESLint v9 flat config does not cascade up the
 * directory tree, so each workspace needs its own config to declare what
 * gets linted. Without this, `pnpm exec eslint ...` from inside this
 * workspace would error with "couldn't find eslint.config.*".
 *
 * Overrides:
 *   - Seed scripts legitimately call console.log for progress output.
 *     The base config flags those as warnings; we run lint with
 *     --max-warnings=0 so warnings would otherwise fail CI.
 *
 * Ignores:
 *   - generated/** is Prisma's emitted client (>100k lines we don't author).
 *   - migrations/** is SQL, not JS/TS.
 */
// eslint-disable-next-line @typescript-eslint/no-require-imports
const base = require('@jobbees/eslint-config');

/** @type {import('eslint').Linter.Config[]} */
module.exports = [
  ...base,
  {
    files: ['seed.ts', 'prisma.config.ts'],
    rules: {
      'no-console': 'off',
    },
  },
  {
    ignores: ['generated/**', 'migrations/**', 'node_modules/**'],
  },
];
