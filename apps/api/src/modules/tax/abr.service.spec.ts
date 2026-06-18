import type { ConfigService } from '@nestjs/config';
import type { RedisService } from '../../redis/redis.service';
import { AbrService } from './abr.service';

function build({ guid = '', nodeEnv = 'development', cached = null as string | null } = {}) {
  const store = { get: jest.fn().mockResolvedValue(cached), set: jest.fn() };
  const config = {
    get: jest.fn((key: string, fallback?: string) => {
      if (key === 'ABR_GUID') return guid;
      if (key === 'NODE_ENV') return nodeEnv;
      return fallback ?? '';
    }),
  };
  const redis = { client: store };
  const service = new AbrService(
    config as unknown as ConfigService,
    redis as unknown as RedisService,
  );
  return { service, store };
}

describe('AbrService', () => {
  it('returns a stub in non-production when no GUID is configured', async () => {
    const { service, store } = build();

    const result = await service.lookup('51824753556');

    expect(result).toEqual({
      abn: '51824753556',
      businessName: 'Test Business Pty Ltd',
      isActive: true,
      gstRegistered: true,
    });
    // Result is cached for next time.
    expect(store.set).toHaveBeenCalledWith(
      'abr:51824753556',
      expect.any(String),
      'EX',
      24 * 60 * 60,
    );
  });

  it('returns the cached result without re-fetching', async () => {
    const cachedResult = {
      abn: '51824753556',
      businessName: 'Cached Co',
      isActive: true,
      gstRegistered: false,
    };
    const { service, store } = build({ cached: JSON.stringify(cachedResult) });

    const result = await service.lookup('51824753556');

    expect(result).toEqual(cachedResult);
    expect(store.set).not.toHaveBeenCalled();
  });

  it('returns null in production when no GUID is configured', async () => {
    const { service } = build({ nodeEnv: 'production' });

    expect(await service.lookup('51824753556')).toBeNull();
  });
});
