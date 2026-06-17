import { RedisService } from '../../redis/redis.service';
import { ReauthService } from './reauth.service';

function build() {
  const redis = {
    client: { set: jest.fn().mockResolvedValue('OK'), exists: jest.fn() },
  };
  return { service: new ReauthService(redis as unknown as RedisService), redis };
}

describe('ReauthService', () => {
  it('grant sets a TTL flag and returns the window length', async () => {
    const { service, redis } = build();
    await expect(service.grant('u1')).resolves.toBe(300);
    expect(redis.client.set).toHaveBeenCalledWith('reauth:u1', '1', 'EX', 300);
  });

  it('isRecent reflects Redis presence', async () => {
    const { service, redis } = build();
    redis.client.exists.mockResolvedValue(1);
    await expect(service.isRecent('u1')).resolves.toBe(true);
    redis.client.exists.mockResolvedValue(0);
    await expect(service.isRecent('u1')).resolves.toBe(false);
  });
});
