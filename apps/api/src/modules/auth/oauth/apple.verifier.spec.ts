import { ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { jwtVerify } from 'jose'; // mapped to test/jose.mock.ts (jest.fn)
import { AppleVerifier } from './apple.verifier';

const mockJwtVerify = jwtVerify as jest.Mock;

function build(clientIds = 'com.seaford.jobbees') {
  const config = { get: jest.fn().mockReturnValue(clientIds) };
  return new AppleVerifier(config as unknown as ConfigService);
}

describe('AppleVerifier', () => {
  beforeEach(() => mockJwtVerify.mockReset());

  it('503 when no client IDs are configured', async () => {
    await expect(build('').verify('tok')).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('returns a normalised identity for a valid token', async () => {
    mockJwtVerify.mockResolvedValue({
      payload: { sub: 'a1', email: 'Bob@Example.com', email_verified: 'true' },
    });
    await expect(build().verify('tok')).resolves.toEqual({
      provider: 'apple',
      providerId: 'a1',
      email: 'bob@example.com',
      emailVerified: true,
    });
  });

  it('401 on an invalid token', async () => {
    mockJwtVerify.mockRejectedValue(new Error('bad signature'));
    await expect(build().verify('tok')).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('401 when the token has no email', async () => {
    mockJwtVerify.mockResolvedValue({ payload: { sub: 'a1' } });
    await expect(build().verify('tok')).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
