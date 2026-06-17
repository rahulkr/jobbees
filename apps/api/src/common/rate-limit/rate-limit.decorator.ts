import { SetMetadata } from '@nestjs/common';

export const RATE_LIMIT_KEY = 'jobbees:rate_limit';

export interface RateLimitOptions {
  /** Max requests allowed within the window. */
  points: number;
  /** Window length in seconds. */
  duration: number;
}

/**
 * Per-route rate limit. Example (security-review skill §D1):
 *   @RateLimit({ points: 5, duration: 60 })
 * Enforced by the globally-registered RateLimitGuard; routes without the
 * decorator are unlimited.
 */
export const RateLimit = (options: RateLimitOptions) => SetMetadata(RATE_LIMIT_KEY, options);
