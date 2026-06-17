import { SetMetadata } from '@nestjs/common';
import { type UserRole } from '@jobbees/prisma';

export const ROLES_KEY = 'jobbees:roles';

/**
 * Restricts a route to the given roles. Enforced by the global RolesGuard
 * (which runs after JwtAuthGuard). Routes without @Roles are role-agnostic.
 *
 *   @Roles(UserRole.TASKER)
 *   @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
 */
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES_KEY, roles);
