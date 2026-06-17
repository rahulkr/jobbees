import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { type UserRole } from '@jobbees/prisma';
import type { Request } from 'express';
import { type CurrentUserData } from '../../common/auth/current-user.decorator';
import { ROLES_KEY } from '../../common/auth/roles.decorator';

/**
 * Global authorization guard. Runs after JwtAuthGuard (so `req.user` is set).
 * Allows routes without @Roles; otherwise requires the user's role to match.
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<UserRole[] | undefined>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!required || required.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest<Request & { user?: CurrentUserData }>();
    const user = request.user;
    if (!user) {
      throw new ForbiddenException('Authentication required');
    }
    if (!required.includes(user.role)) {
      throw new ForbiddenException('Insufficient role');
    }
    return true;
  }
}
