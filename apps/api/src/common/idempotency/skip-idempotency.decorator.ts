import { SetMetadata } from '@nestjs/common';

export const SKIP_IDEMPOTENCY_KEY = 'jobbees:skip-idempotency';

/**
 * Exempts a route from the global [IdempotencyInterceptor]. For endpoints that
 * are mutating but can't carry an `Idempotency-Key` and dedupe another way —
 * e.g. Stripe webhooks (signed, deduped by Stripe event id).
 */
export const SkipIdempotency = () => SetMetadata(SKIP_IDEMPOTENCY_KEY, true);
