import { Global, Module } from '@nestjs/common';
import { RedisService } from './redis.service';

/**
 * Global so idempotency, rate-limit, and future modules can inject the one
 * shared connection without re-importing.
 */
@Global()
@Module({
  providers: [RedisService],
  exports: [RedisService],
})
export class RedisModule {}
