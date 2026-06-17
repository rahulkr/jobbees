import { ExecutionContext, HttpException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

const consumeMock = jest.fn();
jest.mock('rate-limiter-flexible', () => ({
  RateLimiterRedis: jest.fn().mockImplementation(() => ({ consume: consumeMock })),
}));

// Imported after the mock so the guard picks up the mocked RateLimiterRedis.
import { RedisService } from '../../redis/redis.service';
import { RateLimitGuard } from './rate-limit.guard';

function mockContext(): ExecutionContext {
  const request = {
    method: 'POST',
    path: '/auth/login',
    route: { path: '/auth/login' },
    ip: '1.2.3.4',
  };
  return {
    getHandler: () => () => undefined,
    getClass: () => class {},
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext;
}

describe('RateLimitGuard', () => {
  let reflector: { getAllAndOverride: jest.Mock };
  let guard: RateLimitGuard;
  const redis = { client: {} } as unknown as RedisService;

  beforeEach(() => {
    consumeMock.mockReset();
    reflector = { getAllAndOverride: jest.fn() };
    guard = new RateLimitGuard(reflector as unknown as Reflector, redis);
  });

  it('allows requests on routes without @RateLimit', async () => {
    reflector.getAllAndOverride.mockReturnValue(undefined);
    await expect(guard.canActivate(mockContext())).resolves.toBe(true);
    expect(consumeMock).not.toHaveBeenCalled();
  });

  it('allows requests under the limit', async () => {
    reflector.getAllAndOverride.mockReturnValue({ points: 5, duration: 60 });
    consumeMock.mockResolvedValue({});
    await expect(guard.canActivate(mockContext())).resolves.toBe(true);
    expect(consumeMock).toHaveBeenCalledTimes(1);
  });

  it('throws 429 once the limit is exceeded', async () => {
    reflector.getAllAndOverride.mockReturnValue({ points: 1, duration: 60 });
    consumeMock.mockRejectedValue(new Error('rate limit exceeded'));
    await expect(guard.canActivate(mockContext())).rejects.toBeInstanceOf(HttpException);
  });
});
