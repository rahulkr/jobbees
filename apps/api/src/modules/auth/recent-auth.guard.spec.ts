import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ReauthService } from './reauth.service';
import { RecentAuthGuard } from './recent-auth.guard';

function mockContext(user?: { id: string }): ExecutionContext {
  return {
    getHandler: () => () => undefined,
    getClass: () => class {},
    switchToHttp: () => ({ getRequest: () => ({ user }) }),
  } as unknown as ExecutionContext;
}

describe('RecentAuthGuard', () => {
  let reflector: { getAllAndOverride: jest.Mock };
  let reauth: { isRecent: jest.Mock };
  let guard: RecentAuthGuard;

  beforeEach(() => {
    reflector = { getAllAndOverride: jest.fn() };
    reauth = { isRecent: jest.fn() };
    guard = new RecentAuthGuard(
      reflector as unknown as Reflector,
      reauth as unknown as ReauthService,
    );
  });

  it('allows routes without @RequireRecentAuth', async () => {
    reflector.getAllAndOverride.mockReturnValue(undefined);
    await expect(guard.canActivate(mockContext({ id: 'u1' }))).resolves.toBe(true);
    expect(reauth.isRecent).not.toHaveBeenCalled();
  });

  it('allows when recently re-authenticated', async () => {
    reflector.getAllAndOverride.mockReturnValue(true);
    reauth.isRecent.mockResolvedValue(true);
    await expect(guard.canActivate(mockContext({ id: 'u1' }))).resolves.toBe(true);
  });

  it('403 when not recently re-authenticated', async () => {
    reflector.getAllAndOverride.mockReturnValue(true);
    reauth.isRecent.mockResolvedValue(false);
    await expect(guard.canActivate(mockContext({ id: 'u1' }))).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
