import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '@jobbees/prisma';
import { RolesGuard } from './roles.guard';

function mockContext(user?: { id: string; role: UserRole }): ExecutionContext {
  return {
    getHandler: () => () => undefined,
    getClass: () => class {},
    switchToHttp: () => ({ getRequest: () => ({ user }) }),
  } as unknown as ExecutionContext;
}

describe('RolesGuard', () => {
  let reflector: { getAllAndOverride: jest.Mock };
  let guard: RolesGuard;

  beforeEach(() => {
    reflector = { getAllAndOverride: jest.fn() };
    guard = new RolesGuard(reflector as unknown as Reflector);
  });

  it('allows routes without @Roles', () => {
    reflector.getAllAndOverride.mockReturnValue(undefined);
    expect(guard.canActivate(mockContext())).toBe(true);
  });

  it('allows a user whose role is permitted', () => {
    reflector.getAllAndOverride.mockReturnValue([UserRole.TASKER]);
    expect(guard.canActivate(mockContext({ id: 'u1', role: UserRole.TASKER }))).toBe(true);
  });

  it('rejects a user whose role is not permitted', () => {
    reflector.getAllAndOverride.mockReturnValue([UserRole.TASKER]);
    expect(() => guard.canActivate(mockContext({ id: 'u1', role: UserRole.CLIENT }))).toThrow(
      ForbiddenException,
    );
  });

  it('rejects when there is no authenticated user', () => {
    reflector.getAllAndOverride.mockReturnValue([UserRole.ADMIN]);
    expect(() => guard.canActivate(mockContext())).toThrow(ForbiddenException);
  });
});
