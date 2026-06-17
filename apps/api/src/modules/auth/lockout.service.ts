import { Injectable } from '@nestjs/common';
import { AuditLogService } from '../../common/audit/audit-log.service';
import { RedisService } from '../../redis/redis.service';

/**
 * Account lockout (M-231 / SRS NFR-SEC).
 *
 * Failed-attempt counters in Redis with a rolling window:
 * - 10 failed logins → 1h lock (and flag for forced password reset)
 * - 5 failed OTP checks → 1h lock
 * Counters clear on success. Every lockout writes an AuditLog row.
 */
const WINDOW_SECONDS = 60 * 60; // rolling window + lock duration (1h)
const MAX_FAILED_LOGINS = 10;
const MAX_FAILED_OTPS = 5;

interface LockoutContext {
  ipAddress?: string | null;
  userAgent?: string | null;
}

@Injectable()
export class LockoutService {
  constructor(
    private readonly redis: RedisService,
    private readonly audit: AuditLogService,
  ) {}

  // ---- Login (keyed by normalised email) ----

  isLoginLocked(email: string): Promise<boolean> {
    return this.exists(this.lockKey('login', email));
  }

  async recordFailedLogin(email: string, ctx: LockoutContext): Promise<{ locked: boolean }> {
    const count = await this.bump(this.failKey('login', email));
    if (count >= MAX_FAILED_LOGINS) {
      await this.lock('login', email, ctx, {
        reason: 'too_many_failed_logins',
        forcePasswordReset: true,
      });
      return { locked: true };
    }
    return { locked: false };
  }

  clearLogin(email: string): Promise<void> {
    return this.clear('login', email);
  }

  // ---- OTP (keyed by userId) ----

  isOtpLocked(userId: string): Promise<boolean> {
    return this.exists(this.lockKey('otp', userId));
  }

  async recordFailedOtp(userId: string, ctx: LockoutContext): Promise<{ locked: boolean }> {
    const count = await this.bump(this.failKey('otp', userId));
    if (count >= MAX_FAILED_OTPS) {
      await this.lock('otp', userId, ctx, { reason: 'too_many_failed_otps' });
      return { locked: true };
    }
    return { locked: false };
  }

  clearOtp(userId: string): Promise<void> {
    return this.clear('otp', userId);
  }

  // ---- internals ----

  private failKey(domain: string, id: string): string {
    return `lockout:${domain}:fail:${id}`;
  }

  private lockKey(domain: string, id: string): string {
    return `lockout:${domain}:locked:${id}`;
  }

  /** INCR with a window TTL set on first failure. Returns the running count. */
  private async bump(key: string): Promise<number> {
    const count = await this.redis.client.incr(key);
    if (count === 1) {
      await this.redis.client.expire(key, WINDOW_SECONDS);
    }
    return count;
  }

  private exists(key: string): Promise<boolean> {
    return this.redis.client.exists(key).then((n) => n === 1);
  }

  private async lock(
    domain: 'login' | 'otp',
    id: string,
    ctx: LockoutContext,
    diff: Record<string, unknown>,
  ): Promise<void> {
    await this.redis.client.set(this.lockKey(domain, id), '1', 'EX', WINDOW_SECONDS);
    await this.audit.record({
      action: `auth.account_locked.${domain}`,
      resourceType: 'User',
      resourceId: id,
      diff,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
    });
  }

  private async clear(domain: string, id: string): Promise<void> {
    await this.redis.client.del(this.failKey(domain, id), this.lockKey(domain, id));
  }
}
