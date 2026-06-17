import { SetMetadata } from '@nestjs/common';

export const REQUIRE_RECENT_AUTH_KEY = 'jobbees:require_recent_auth';

/**
 * Marks a route as requiring a recent password re-auth (step-up). Enforced by
 * the global RecentAuthGuard — the client must call POST /auth/reauth first,
 * else the route returns 403 { code: 'REAUTH_REQUIRED' }.
 *
 * Used by change-email / change-phone in Sprint 2.
 */
export const RequireRecentAuth = () => SetMetadata(REQUIRE_RECENT_AUTH_KEY, true);
