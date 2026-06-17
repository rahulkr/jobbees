import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { CookieOptions, Request, Response } from 'express';
import { randomBytes } from 'node:crypto';
import { type TokenPair } from './token.service';

export const ACCESS_COOKIE = 'jb_access';
export const REFRESH_COOKIE = 'jb_refresh';
export const CSRF_COOKIE = 'XSRF-TOKEN';
export const SURFACE_HEADER = 'x-surface';

const MS_PER_DAY = 86_400_000;

/** Read a cookie by its (constant) name from a cookie-parser'd request. */
export function readCookie(req: Request, name: string): string | undefined {
  const cookies = req.cookies as Record<string, string | undefined> | undefined;
  // eslint-disable-next-line security/detect-object-injection -- `name` is an internal constant cookie name, never user input
  return cookies?.[name];
}

/**
 * Per-surface session delivery (ADR 006).
 *
 * Web (X-Surface: web) → access + refresh as HttpOnly cookies + a JS-readable
 * XSRF-TOKEN cookie (double-submit CSRF); the raw tokens are never in the body.
 * Mobile (default) → the token pair in the JSON body (Bearer).
 */
@Injectable()
export class SessionCookieService {
  constructor(private readonly config: ConfigService) {}

  isWeb(req: Request): boolean {
    return req.header(SURFACE_HEADER)?.toLowerCase() === 'web';
  }

  deliver(req: Request, res: Response, pair: TokenPair): TokenPair | { csrfToken: string } {
    if (!this.isWeb(req)) {
      return pair;
    }
    const accessMs = this.config.get<number>('JWT_ACCESS_TTL_SECONDS', 900) * 1000;
    const refreshMs = this.config.get<number>('JWT_REFRESH_TTL_DAYS', 30) * MS_PER_DAY;

    res.cookie(ACCESS_COOKIE, pair.accessToken, this.cookieOpts(accessMs));
    res.cookie(REFRESH_COOKIE, pair.refreshToken, this.cookieOpts(refreshMs));

    // Readable by JS so the SPA can echo it in the X-XSRF-TOKEN header.
    const csrfToken = randomBytes(32).toString('base64url');
    res.cookie(CSRF_COOKIE, csrfToken, this.cookieOpts(refreshMs, false));
    return { csrfToken };
  }

  clear(res: Response): void {
    res.clearCookie(ACCESS_COOKIE, { path: '/' });
    res.clearCookie(REFRESH_COOKIE, { path: '/' });
    res.clearCookie(CSRF_COOKIE, { path: '/' });
  }

  private cookieOpts(maxAge: number, httpOnly = true): CookieOptions {
    return {
      httpOnly,
      secure: this.config.get<string>('NODE_ENV') === 'production',
      sameSite: 'lax',
      path: '/',
      maxAge,
    };
  }
}
