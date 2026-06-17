import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import { IS_PUBLIC_KEY } from '../../common/auth/public.decorator';
import { type CurrentUserData } from '../../common/auth/current-user.decorator';
import { ACCESS_COOKIE, readCookie } from './session-cookie.service';
import { TokenService } from './token.service';

const BEARER_PREFIX = 'Bearer ';

interface AuthRequest extends Request {
  user?: CurrentUserData;
}

/** Bearer header (mobile) or the jb_access cookie (web) — whichever is present. */
function extractToken(request: AuthRequest): string | undefined {
  const header = request.header('authorization');
  if (header?.startsWith(BEARER_PREFIX)) {
    return header.slice(BEARER_PREFIX.length).trim();
  }
  return readCookie(request, ACCESS_COOKIE);
}

/**
 * Global guard: verifies the access JWT (from the Bearer header or the
 * jb_access cookie) and attaches `{ id, role }`. Routes tagged @Public skip it.
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly tokens: TokenService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest<AuthRequest>();
    const token = extractToken(request);
    if (!token) {
      throw new UnauthorizedException('Missing access token');
    }

    try {
      const payload = await this.tokens.verifyAccess(token);
      request.user = { id: payload.sub, role: payload.role };
      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }
}
