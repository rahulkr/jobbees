/**
 * Root ESLint config (flat-config / ESLint v9+).
 *
 * Used when ESLint is invoked from the repo root with file path arguments —
 * the most common case is lefthook's pre-commit hook passing `{staged_files}`
 * to `pnpm exec eslint`. ESLint v9 only resolves `eslint.config.(js|mjs|cjs)`
 * from the cwd, so without this file the hook errors with
 * "ESLint couldn't find an eslint.config.(js|mjs|cjs) file."
 *
 * For workspace-local invocations (`pnpm exec eslint` from inside apps/* or
 * packages/*), that workspace's own eslint.config.* takes precedence — flat
 * config does not cascade up the directory tree the way the old .eslintrc did,
 * so this file is only consulted when ESLint runs at the root.
 *
 * Composition: pulls the shared base from @jobbees/eslint-config, then layers
 * file-specific overrides for legitimate edge cases (seed scripts that need
 * console.log), and a generous ignores list that keeps lefthook fast.
 */
// eslint-disable-next-line @typescript-eslint/no-require-imports
const base = require('@jobbees/eslint-config');

/** @type {import('eslint').Linter.Config[]} */
module.exports = [
  ...base,

  // Seed scripts + ops scripts legitimately use console.log for progress
  // output. The base config flags those as warnings; lefthook runs ESLint
  // with --max-warnings=0, so warnings would fail the commit.
  {
    files: [
      'packages/prisma/seed.ts',
      'packages/prisma/**/*.config.ts',
      'scripts/**/*.{ts,js,mjs,cjs}',
    ],
    rules: {
      'no-console': 'off',
    },
  },

  // Global ignores. Order: build artifacts, generated code, non-JS surfaces
  // (mobile is Dart), docs, and CI helpers that are not part of the source.
  {
    ignores: [
      'apps/mobile/**', // Flutter / Dart, not lint-able by ESLint
      'packages/prisma/generated/**', // Prisma-generated client
      'packages/prisma/migrations/**', // SQL files
      'docs/**', // Markdown only
      'inventory/**', // CSVs + READMEs only
      'ops/**', // YAML + shell + SQL
      '**/node_modules/**',
      '**/dist/**',
      '**/build/**',
      '**/.next/**',
      '**/.turbo/**',
      '**/coverage/**',
    ],
  },
];
