// eslint-disable-next-line @typescript-eslint/no-require-imports
const base = require('@jobbees/eslint-config');

module.exports = [
  ...base,
  {
    files: ['seed.ts', 'prisma.config.ts'],
    rules: { 'no-console': 'off' },
  },
  { ignores: ['generated/**', 'migrations/**', 'node_modules/**'] },
];
