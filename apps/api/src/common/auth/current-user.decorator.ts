import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { type UserRole } from '@jobbees/prisma';
import type { Request } from 'express';

export interface CurrentUserData {
  id: string;
  role: UserRole;
}

/**
 * Extracts the authenticated user (set on the request by JwtAuthGuard).
 * Only valid on guarded routes.
 */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): CurrentUserData | undefined => {
    const request = ctx.switchToHttp().getRequest<Request & { user?: CurrentUserData }>();
    return request.user;
  },
);
