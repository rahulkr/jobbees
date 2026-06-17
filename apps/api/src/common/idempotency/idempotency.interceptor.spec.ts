import {
  BadRequestException,
  CallHandler,
  ConflictException,
  ExecutionContext,
} from '@nestjs/common';
import { lastValueFrom, of } from 'rxjs';
import { RedisService } from '../../redis/redis.service';
import { IdempotencyInterceptor } from './idempotency.interceptor';

function mockContext(method: string, headers: Record<string, string>, path = '/auth/signup') {
  const request = {
    method,
    path,
    header: (h: string) => headers[h.toLowerCase()],
  };
  const response = { statusCode: 201, status: jest.fn() };
  const ctx = {
    switchToHttp: () => ({
      getRequest: () => request,
      getResponse: () => response,
    }),
  } as unknown as ExecutionContext;
  return { ctx, response };
}

const handlerReturning = (value: unknown): CallHandler => ({
  handle: () => of(value),
});

describe('IdempotencyInterceptor', () => {
  let redis: { client: { get: jest.Mock; set: jest.Mock; del: jest.Mock } };
  let interceptor: IdempotencyInterceptor;

  beforeEach(() => {
    redis = { client: { get: jest.fn(), set: jest.fn(), del: jest.fn() } };
    interceptor = new IdempotencyInterceptor(redis as unknown as RedisService);
  });

  it('passes non-mutating methods straight through', async () => {
    const { ctx } = mockContext('GET', {});
    const obs = await interceptor.intercept(ctx, handlerReturning('ok'));
    await expect(lastValueFrom(obs)).resolves.toBe('ok');
    expect(redis.client.get).not.toHaveBeenCalled();
  });

  it('rejects a mutating request without an Idempotency-Key', async () => {
    const { ctx } = mockContext('POST', {});
    await expect(interceptor.intercept(ctx, handlerReturning('x'))).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('replays the cached response on a repeated key', async () => {
    redis.client.get.mockResolvedValue(
      JSON.stringify({ status: 'done', statusCode: 201, body: { id: 'u1' } }),
    );
    const { ctx, response } = mockContext('POST', { 'idempotency-key': 'k1' });
    const obs = await interceptor.intercept(ctx, handlerReturning('SHOULD_NOT_RUN'));
    await expect(lastValueFrom(obs)).resolves.toEqual({ id: 'u1' });
    expect(response.status).toHaveBeenCalledWith(201);
  });

  it('returns 409 when the same key is already in progress', async () => {
    redis.client.get.mockResolvedValue(JSON.stringify({ status: 'pending' }));
    const { ctx } = mockContext('POST', { 'idempotency-key': 'k1' });
    await expect(interceptor.intercept(ctx, handlerReturning('x'))).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('runs the handler and caches the result on first call', async () => {
    redis.client.get.mockResolvedValue(null);
    redis.client.set.mockResolvedValue('OK');
    const { ctx } = mockContext('POST', { 'idempotency-key': 'k1' });
    const obs = await interceptor.intercept(ctx, handlerReturning({ id: 'new' }));
    await expect(lastValueFrom(obs)).resolves.toEqual({ id: 'new' });
    expect(redis.client.set).toHaveBeenCalledTimes(2); // lock + result
  });

  it('returns 409 when the lock cannot be acquired (race)', async () => {
    redis.client.get.mockResolvedValue(null);
    redis.client.set.mockResolvedValue(null); // SET NX failed
    const { ctx } = mockContext('POST', { 'idempotency-key': 'k1' });
    await expect(interceptor.intercept(ctx, handlerReturning('x'))).rejects.toBeInstanceOf(
      ConflictException,
    );
  });
});
