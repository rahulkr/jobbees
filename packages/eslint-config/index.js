/**
 * Base ESLint config for the JOBBees monorepo.
 *
 * Flat-config format (ESLint v9+). Compose from each app via:
 *
 *   // apps/<name>/eslint.config.js
 *   const base = require('@jobbees/eslint-config');
 *   module.exports = [...base, { ... overrides ... }];
 */
const js = require('@eslint/js');
const tseslint = require('typescript-eslint');
const securityPlugin = require('eslint-plugin-security');
const prettierConfig = require('eslint-config-prettier');
const globals = require('globals');

/** @type {import('eslint').Linter.Config[]} */
module.exports = [
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: {
        ...globals.node,
        ...globals.es2022,
      },
    },
    plugins: {
      security: securityPlugin,
    },
    rules: {
      // Security plugin (legacy preset — official one for v9)
      'security/detect-object-injection': 'warn',
      'security/detect-non-literal-fs-filename': 'warn',
      'security/detect-eval-with-expression': 'error',
      'security/detect-buffer-noassert': 'error',

      // TypeScript
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-non-null-assertion': 'warn',

      // General
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'no-debugger': 'error',
      eqeqeq: ['error', 'always'],
    },
  },
  // Prettier compat — disables ESLint rules that conflict with Prettier formatting.
  // Must come AFTER the recommended configs so it can override them.
  prettierConfig,
  // Global ignores — applied to every config in the array.
  {
    ignores: [
      '**/dist/**',
      '**/build/**',
      '**/node_modules/**',
      '**/generated/**',
      '**/.next/**',
      '**/.turbo/**',
      '**/coverage/**',
    ],
  },
];
