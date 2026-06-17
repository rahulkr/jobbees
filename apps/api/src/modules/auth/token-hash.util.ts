import { createHash, randomBytes } from 'node:crypto';

const DEFAULT_TOKEN_BYTES = 32;

/** Opaque, URL-safe random token (the value emailed/handed to the client). */
export function generateRawToken(bytes = DEFAULT_TOKEN_BYTES): string {
  return randomBytes(bytes).toString('base64url');
}

/** SHA-256 hex — only the hash is ever stored (never the raw token). */
export function hashToken(raw: string): string {
  return createHash('sha256').update(raw).digest('hex');
}
