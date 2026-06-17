import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import { type CurrentUserData } from '../../common/auth/current-user.decorator';
import { REQUIRE_RECENT_AUTH_KEY } from '../../common/auth/require-recent-auth.decorator';
import { ReauthService } from './reauth.service';

/**
 * Global guard: routes tagged @RequireRecentAuth need a password re-auth within
 * the step-up window. Untagged routes pass through.
 */
@Injectable()
export class RecentAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly reauth: ReauthService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const required = this.reflector.getAllAndOverride<boolean>(REQUIRE_RECENT_AUTH_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!required) {
      return true;
    }

    const request = context.switchToHttp().getRequest<Request & { user?: CurrentUserData }>();
    if (!request.user) {
      throw new ForbiddenException('Authentication required');
    }
    if (!(await this.reauth.isRecent(request.user.id))) {
      throw new ForbiddenException({
        message: 'Recent re-authentication required',
        code: 'REAUTH_REQUIRED',
      });
    }
    return true;
  }
}
