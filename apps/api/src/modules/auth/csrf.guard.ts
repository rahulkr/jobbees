import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import type { Request } from 'express';
import { ACCESS_COOKIE, CSRF_COOKIE, REFRESH_COOKIE, readCookie } from './session-cookie.service';

const SAFE_METHODS = new Set(['GET', 'HEAD', 'OPTIONS']);
const CSRF_HEADER = 'x-xsrf-token';

/**
 * Double-submit CSRF protection for cookie-authenticated requests.
 *
 * Only applies when the request is mutating AND carries our session cookies
 * (i.e. web/cookie auth). Bearer requests (mobile) and pre-session requests
 * (login/signup with no cookie yet) carry no ambient credentials, so they're
 * exempt. The X-XSRF-TOKEN header must equal the XSRF-TOKEN cookie.
 */
@Injectable()
export class CsrfGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<Request>();
    if (SAFE_METHODS.has(request.method)) {
      return true;
    }

    const cookieAuth = Boolean(
      readCookie(request, ACCESS_COOKIE) ?? readCookie(request, REFRESH_COOKIE),
    );
    if (!cookieAuth) {
      return true;
    }

    const headerToken = request.header(CSRF_HEADER);
    const cookieToken = readCookie(request, CSRF_COOKIE);
    if (!headerToken || !cookieToken || headerToken !== cookieToken) {
      throw new ForbiddenException({
        message: 'CSRF token missing or invalid',
        code: 'CSRF_FAILED',
      });
    }
    return true;
  }
}
