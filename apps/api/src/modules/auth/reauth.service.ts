import { Injectable } from '@nestjs/common';
import { RedisService } from '../../redis/redis.service';

/** Step-up auth window: how long a password re-auth stays valid. */
const REAUTH_TTL_SECONDS = 300; // 5 minutes

/**
 * Tracks recent password re-authentication (step-up auth) in Redis. Sensitive
 * actions (change email/phone, etc.) require a proof granted within the window.
 */
@Injectable()
export class ReauthService {
  constructor(private readonly redis: RedisService) {}

  private key(userId: string): string {
    return `reauth:${userId}`;
  }

  async grant(userId: string): Promise<number> {
    await this.redis.client.set(this.key(userId), '1', 'EX', REAUTH_TTL_SECONDS);
    return REAUTH_TTL_SECONDS;
  }

  isRecent(userId: string): Promise<boolean> {
    return this.redis.client.exists(this.key(userId)).then((n) => n === 1);
  }
}
