// Jest-only shim for @paralleldrive/cuid2.
//
// cuid2 v3 is ESM-only. Node 24 loads it fine at runtime (require(ESM) is
// supported), but jest's CJS module sandbox cannot. We map the package to this
// CJS implementation via moduleNameMapper. Tests don't care about the exact id
// format — only that ids are unique strings — so a UUID-derived id suffices.
//
// NOTE: the mapper applies to *every* importer, including transitive deps like
// formidable (used by supertest), which calls `init()`. So this shim mirrors
// the cuid2 surface those callers use, not just `createId`. Production uses the
// real cuid2.
import { randomUUID } from 'node:crypto';

export const createId = (): string => randomUUID().replace(/-/g, '');

/** cuid2.init(opts) → a configured id generator. */
export const init = (_options?: unknown): (() => string) => createId;

export const getConstants = (): Record<string, never> => ({});

export const isCuid = (value: unknown): boolean => typeof value === 'string' && value.length > 0;
