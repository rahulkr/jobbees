/**
 * apps/api ESLint configuration (NestJS).
 *
 * Composes the shared base from `@jobbees/eslint-config` and adds
 * NestJS-specific tweaks for decorators, dependency injection, and Jest.
 *
 * Flat-config format (ESLint v9+).
 */
const baseConfig = require('@jobbees/eslint-config');
const globals = require('globals');

/** @type {import('eslint').Linter.Config[]} */
module.exports = [
  ...baseConfig,
  {
    languageOptions: {
      parserOptions: {
        project: './tsconfig.json',
        tsconfigRootDir: __dirname,
      },
      globals: {
        ...globals.node,
        ...globals.jest,
      },
    },
    // NestJS-specific relaxations
    // (Nest's heavy decorator usage + DI patterns make these unhelpful)
    rules: {
      '@typescript-eslint/interface-name-prefix': 'off',
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/explicit-module-boundary-types': 'off',
      '@typescript-eslint/no-explicit-any': 'off',
    },
  },
  // Don't lint the config file itself or build output
  {
    ignores: ['eslint.config.js', 'dist/**', 'node_modules/**', 'coverage/**'],
  },
];
