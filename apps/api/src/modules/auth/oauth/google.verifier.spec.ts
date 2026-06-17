import { ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

const mockVerifyIdToken = jest.fn();
jest.mock('google-auth-library', () => ({
  OAuth2Client: jest.fn().mockImplementation(() => ({
    verifyIdToken: (...args: unknown[]) => mockVerifyIdToken(...args),
  })),
}));

import { GoogleVerifier } from './google.verifier';

function build(clientIds = 'client-1.apps.googleusercontent.com') {
  const config = { get: jest.fn().mockReturnValue(clientIds) };
  return new GoogleVerifier(config as unknown as ConfigService);
}

describe('GoogleVerifier', () => {
  beforeEach(() => mockVerifyIdToken.mockReset());

  it('503 when no client IDs are configured', async () => {
    await expect(build('').verify('tok')).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('returns a normalised identity for a valid token', async () => {
    mockVerifyIdToken.mockResolvedValue({
      getPayload: () => ({
        sub: 'g1',
        email: 'Ada@Example.com',
        email_verified: true,
        given_name: 'Ada',
        family_name: 'Lovelace',
      }),
    });
    await expect(build().verify('tok')).resolves.toEqual({
      provider: 'google',
      providerId: 'g1',
      email: 'ada@example.com',
      emailVerified: true,
      firstName: 'Ada',
      lastName: 'Lovelace',
    });
  });

  it('401 on an invalid token', async () => {
    mockVerifyIdToken.mockRejectedValue(new Error('bad signature'));
    await expect(build().verify('tok')).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('401 when the token has no email', async () => {
    mockVerifyIdToken.mockResolvedValue({ getPayload: () => ({ sub: 'g1' }) });
    await expect(build().verify('tok')).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
