import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { RedisModule } from '../redis/redis.module';
import { IdempotencyInterceptor } from './idempotency/idempotency.interceptor';
import { RateLimitGuard } from './rate-limit/rate-limit.guard';
import { RequestIdMiddleware } from './request-id/request-id.middleware';

/**
 * Cross-cutting infra wired app-wide:
 * - IdempotencyInterceptor (global) — every mutating request is idempotent.
 * - RateLimitGuard (global) — enforces `@RateLimit` where present, no-op else.
 * - RequestIdMiddleware — request-id correlation on every route.
 */
@Module({
  imports: [RedisModule],
  providers: [
    { provide: APP_INTERCEPTOR, useClass: IdempotencyInterceptor },
    { provide: APP_GUARD, useClass: RateLimitGuard },
  ],
})
export class CommonModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(RequestIdMiddleware).forRoutes('*');
  }
}
