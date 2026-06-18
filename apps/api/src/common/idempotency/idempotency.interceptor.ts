import {
  BadRequestException,
  CallHandler,
  ConflictException,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request, Response } from 'express';
import { Observable, of } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';
import { RedisService } from '../../redis/redis.service';
import { SKIP_IDEMPOTENCY_KEY } from './skip-idempotency.decorator';

const MUTATING_METHODS = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);
const HEADER = 'idempotency-key';
const RESULT_TTL_SECONDS = 60 * 60 * 24; // 24h — replay window
const LOCK_TTL_SECONDS = 60; // safety release if a request dies mid-flight

interface CachedResult {
  status: 'pending' | 'done';
  statusCode?: number;
  body?: unknown;
}

/**
 * Enforces idempotency on every mutating request (CLAUDE.md / PROJECT_CONTEXT §6).
 *
 * - Non-mutating methods pass straight through.
 * - Mutating methods require an `Idempotency-Key` header (400 if missing).
 * - First request acquires a Redis lock, runs, then caches {statusCode, body}
 *   for 24h. A replay with the same key returns the cached response verbatim.
 * - A concurrent in-flight request with the same key gets 409.
 * - On handler error the lock is released so the client may retry.
 *
 * Registered globally (APP_INTERCEPTOR) so no mutating endpoint can forget it.
 */
@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  constructor(
    private readonly redis: RedisService,
    private readonly reflector: Reflector,
  ) {}

  async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<unknown>> {
    const http = context.switchToHttp();
    const request = http.getRequest<Request>();

    const skip = this.reflector.getAllAndOverride<boolean>(SKIP_IDEMPOTENCY_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (skip || !MUTATING_METHODS.has(request.method)) {
      return next.handle();
    }

    const key = request.header(HEADER);
    if (!key) {
      throw new BadRequestException('Idempotency-Key header is required');
    }

    const redisKey = `idem:${request.method}:${request.path}:${key}`;
    const response = http.getResponse<Response>();

    const existing = await this.redis.client.get(redisKey);
    if (existing) {
      const cached = JSON.parse(existing) as CachedResult;
      if (cached.status === 'pending') {
        throw new ConflictException('A request with this Idempotency-Key is already in progress');
      }
      if (cached.statusCode) {
        response.status(cached.statusCode);
      }
      return of(cached.body);
    }

    const lock = await this.redis.client.set(
      redisKey,
      JSON.stringify({ status: 'pending' } satisfies CachedResult),
      'EX',
      LOCK_TTL_SECONDS,
      'NX',
    );
    if (lock !== 'OK') {
      throw new ConflictException('A request with this Idempotency-Key is already in progress');
    }

    return next.handle().pipe(
      tap((body: unknown) => {
        const result: CachedResult = {
          status: 'done',
          statusCode: response.statusCode,
          body,
        };
        void this.redis.client.set(redisKey, JSON.stringify(result), 'EX', RESULT_TTL_SECONDS);
      }),
      catchError((err: unknown) => {
        // Release the lock so a failed request can be retried.
        void this.redis.client.del(redisKey);
        throw err;
      }),
    );
  }
}
