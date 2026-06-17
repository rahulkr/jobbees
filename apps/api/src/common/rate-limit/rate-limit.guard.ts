import {
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import { RateLimiterRedis } from 'rate-limiter-flexible';
import { RedisService } from '../../redis/redis.service';
import { RATE_LIMIT_KEY, type RateLimitOptions } from './rate-limit.decorator';

/**
 * Enforces `@RateLimit({ points, duration })` using rate-limiter-flexible over
 * Redis. Keyed by route + client IP, so each endpoint has its own budget.
 * Registered globally; routes without the decorator are unaffected.
 */
@Injectable()
export class RateLimitGuard implements CanActivate {
  /** One limiter per distinct points:duration config, created lazily. */
  private readonly limiters = new Map<string, RateLimiterRedis>();

  constructor(
    private readonly reflector: Reflector,
    private readonly redis: RedisService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const options = this.reflector.getAllAndOverride<RateLimitOptions | undefined>(RATE_LIMIT_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!options) {
      return true;
    }

    const request = context.switchToHttp().getRequest<Request>();
    const route = request.route?.path ?? request.path;
    const consumerKey = `${request.method}:${route}:${request.ip ?? 'unknown'}`;

    try {
      await this.getLimiter(options).consume(consumerKey);
      return true;
    } catch {
      throw new HttpException('Too many requests', HttpStatus.TOO_MANY_REQUESTS);
    }
  }

  private getLimiter(options: RateLimitOptions): RateLimiterRedis {
    const cacheKey = `${options.points}:${options.duration}`;
    let limiter = this.limiters.get(cacheKey);
    if (!limiter) {
      limiter = new RateLimiterRedis({
        storeClient: this.redis.client,
        keyPrefix: `rl:${cacheKey}`,
        points: options.points,
        duration: options.duration,
      });
      this.limiters.set(cacheKey, limiter);
    }
    return limiter;
  }
}
