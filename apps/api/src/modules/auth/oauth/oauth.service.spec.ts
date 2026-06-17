import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import { UserRole } from '@jobbees/prisma';
import { AuditLogService } from '../../../common/audit/audit-log.service';
import { UsersService } from '../../users/users.service';
import { TokenService } from '../token.service';
import { AppleVerifier } from './apple.verifier';
import { GoogleVerifier } from './google.verifier';
import { OAuthService } from './oauth.service';

const TOKENS = { accessToken: 'a', refreshToken: 'r' };
const CTX = { ipAddress: '1.2.3.4', userAgent: 'jest' };

function build() {
  const google = { verify: jest.fn() };
  const apple = { verify: jest.fn() };
  const users = { findByEmail: jest.fn(), createOAuthUser: jest.fn() };
  const tokens = { issueForUser: jest.fn().mockResolvedValue(TOKENS) };
  const audit = { record: jest.fn().mockResolvedValue(undefined) };
  const service = new OAuthService(
    google as unknown as GoogleVerifier,
    apple as unknown as AppleVerifier,
    users as unknown as UsersService,
    tokens as unknown as TokenService,
    audit as unknown as AuditLogService,
  );
  return { service, google, apple, users, tokens, audit };
}

describe('OAuthService', () => {
  it('rejects an unknown provider with 400', async () => {
    const { service } = build();
    await expect(service.login('facebook', { idToken: 't' }, CTX)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('rejects an unverified provider email', async () => {
    const { service, google } = build();
    google.verify.mockResolvedValue({
      provider: 'google',
      providerId: 'g1',
      email: 'a@example.com',
      emailVerified: false,
    });
    await expect(service.login('google', { idToken: 't' }, CTX)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('creates a new user on first Google login + issues tokens', async () => {
    const { service, google, users, audit } = build();
    google.verify.mockResolvedValue({
      provider: 'google',
      providerId: 'g1',
      email: 'a@example.com',
      emailVerified: true,
      firstName: 'Ada',
      lastName: 'Lovelace',
    });
    users.findByEmail.mockResolvedValue(null);
    users.createOAuthUser.mockResolvedValue({ id: 'u1', role: UserRole.CLIENT });

    const res = await service.login('google', { idToken: 't' }, CTX);
    expect(res).toEqual(TOKENS);
    expect(users.createOAuthUser).toHaveBeenCalledWith(
      expect.objectContaining({ email: 'a@example.com', emailVerified: true }),
    );
    expect(audit.record).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'user.signup_oauth.google' }),
    );
  });

  it('links to an existing user by verified email (no new user)', async () => {
    const { service, apple, users, audit } = build();
    apple.verify.mockResolvedValue({
      provider: 'apple',
      providerId: 'a1',
      email: 'b@example.com',
      emailVerified: true,
    });
    users.findByEmail.mockResolvedValue({ id: 'u2', role: UserRole.TASKER });

    const res = await service.login('apple', { idToken: 't' }, CTX);
    expect(res).toEqual(TOKENS);
    expect(users.createOAuthUser).not.toHaveBeenCalled();
    expect(audit.record).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'auth.oauth_login.apple' }),
    );
  });
});
