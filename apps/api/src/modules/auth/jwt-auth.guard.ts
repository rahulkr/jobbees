import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import { IS_PUBLIC_KEY } from '../../common/auth/public.decorator';
import { type CurrentUserData } from '../../common/auth/current-user.decorator';
import { TokenService } from './token.service';

const BEARER_PREFIX = 'Bearer ';

/**
 * Global guard: verifies the access JWT and attaches `{ id, role }` to the
 * request. Routes tagged @Public (signup/login/refresh/logout/health) skip it.
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

    const request = context.switchToHttp().getRequest<Request & { user?: CurrentUserData }>();
    const header = request.header('authorization');
    if (!header?.startsWith(BEARER_PREFIX)) {
      throw new UnauthorizedException('Missing bearer token');
    }

    try {
      const payload = await this.tokens.verifyAccess(header.slice(BEARER_PREFIX.length).trim());
      request.user = { id: payload.sub, role: payload.role };
      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }
}
