import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

/**
 * Single shared ioredis connection.
 *
 * Backs idempotency caching, rate limiting, and (later) sessions / BullMQ.
 * Exposes the raw `client` for consumers that need Redis commands directly.
 */
@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  readonly client: Redis;

  constructor(config: ConfigService) {
    this.client = new Redis(config.getOrThrow<string>('REDIS_URL'), {
      maxRetriesPerRequest: 3,
    });
    this.client.on('error', (err: Error) => this.logger.error(`Redis error: ${err.message}`));
  }

  async onModuleInit(): Promise<void> {
    await this.client.ping();
    this.logger.log('Redis connected');
  }

  async onModuleDestroy(): Promise<void> {
    await this.client.quit();
  }
}
