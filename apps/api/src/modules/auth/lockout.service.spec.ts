import { AuditLogService } from '../../common/audit/audit-log.service';
import { RedisService } from '../../redis/redis.service';
import { LockoutService } from './lockout.service';

function build() {
  const redis = {
    client: {
      incr: jest.fn(),
      expire: jest.fn().mockResolvedValue(1),
      exists: jest.fn(),
      set: jest.fn().mockResolvedValue('OK'),
      del: jest.fn().mockResolvedValue(1),
    },
  };
  const audit = { record: jest.fn().mockResolvedValue(undefined) };
  const service = new LockoutService(
    redis as unknown as RedisService,
    audit as unknown as AuditLogService,
  );
  return { service, redis, audit };
}

const CTX = { ipAddress: '1.2.3.4', userAgent: 'jest' };

describe('LockoutService', () => {
  it('sets the window TTL on the first failed login only', async () => {
    const { service, redis } = build();
    redis.client.incr.mockResolvedValue(1);
    await service.recordFailedLogin('a@example.com', CTX);
    expect(redis.client.expire).toHaveBeenCalledTimes(1);

    redis.client.incr.mockResolvedValue(2);
    await service.recordFailedLogin('a@example.com', CTX);
    expect(redis.client.expire).toHaveBeenCalledTimes(1); // not bumped again
  });

  it('locks + audits after 10 failed logins', async () => {
    const { service, redis, audit } = build();
    redis.client.incr.mockResolvedValue(10);
    const res = await service.recordFailedLogin('a@example.com', CTX);
    expect(res.locked).toBe(true);
    expect(redis.client.set).toHaveBeenCalled();
    expect(audit.record).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'auth.account_locked.login' }),
    );
  });

  it('locks after 5 failed OTPs', async () => {
    const { service, redis } = build();
    redis.client.incr.mockResolvedValue(5);
    const res = await service.recordFailedOtp('u1', CTX);
    expect(res.locked).toBe(true);
  });

  it('does not lock below the OTP threshold', async () => {
    const { service, redis } = build();
    redis.client.incr.mockResolvedValue(4);
    const res = await service.recordFailedOtp('u1', CTX);
    expect(res.locked).toBe(false);
    expect(redis.client.set).not.toHaveBeenCalled();
  });

  it('reports locked state from Redis', async () => {
    const { service, redis } = build();
    redis.client.exists.mockResolvedValue(1);
    await expect(service.isLoginLocked('a@example.com')).resolves.toBe(true);
    redis.client.exists.mockResolvedValue(0);
    await expect(service.isOtpLocked('u1')).resolves.toBe(false);
  });

  it('clears both counter + lock keys on success', async () => {
    const { service, redis } = build();
    await service.clearLogin('a@example.com');
    expect(redis.client.del).toHaveBeenCalledWith(
      'lockout:login:fail:a@example.com',
      'lockout:login:locked:a@example.com',
    );
  });
});
