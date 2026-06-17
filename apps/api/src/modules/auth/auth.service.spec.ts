import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { UserRole } from '@jobbees/prisma';
import { AuditLogService } from '../../common/audit/audit-log.service';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';
import { PasswordService } from './password.service';
import { TokenService } from './token.service';

const TOKENS = { accessToken: 'a', refreshToken: 'r' };
const CTX = { ipAddress: '127.0.0.1', userAgent: 'jest' };

function build() {
  const users = {
    findByEmail: jest.fn(),
    findById: jest.fn(),
    create: jest.fn(),
  };
  const passwords = { hash: jest.fn(), verify: jest.fn() };
  const tokens = {
    issueForUser: jest.fn().mockResolvedValue(TOKENS),
    rotate: jest.fn(),
    revoke: jest.fn(),
  };
  const audit = { record: jest.fn().mockResolvedValue(undefined) };
  const service = new AuthService(
    users as unknown as UsersService,
    passwords as unknown as PasswordService,
    tokens as unknown as TokenService,
    audit as unknown as AuditLogService,
  );
  return { service, users, passwords, tokens, audit };
}

describe('AuthService', () => {
  describe('signup', () => {
    it('creates the user, audits, and issues tokens', async () => {
      const { service, users, passwords, audit } = build();
      users.findByEmail.mockResolvedValue(null);
      passwords.hash.mockResolvedValue('hashed');
      users.create.mockResolvedValue({ id: 'u1', role: UserRole.CLIENT });

      const result = await service.signup(
        {
          email: 'New@Example.com',
          password: 'a-strong-passphrase',
          firstName: 'New',
          lastName: 'User',
        },
        CTX,
      );

      expect(result).toEqual(TOKENS);
      expect(users.create).toHaveBeenCalledWith(
        expect.objectContaining({ email: 'new@example.com', role: UserRole.CLIENT }),
      );
      expect(audit.record).toHaveBeenCalledWith(expect.objectContaining({ action: 'user.signup' }));
    });

    it('rejects a duplicate email', async () => {
      const { service, users } = build();
      users.findByEmail.mockResolvedValue({ id: 'existing' });
      await expect(
        service.signup(
          {
            email: 'dupe@example.com',
            password: 'a-strong-passphrase',
            firstName: 'A',
            lastName: 'B',
          },
          CTX,
        ),
      ).rejects.toBeInstanceOf(ConflictException);
    });
  });

  describe('login', () => {
    it('issues tokens on valid credentials', async () => {
      const { service, users, passwords, audit } = build();
      users.findByEmail.mockResolvedValue({
        id: 'u1',
        role: UserRole.CLIENT,
        passwordHash: 'hashed',
      });
      passwords.verify.mockResolvedValue(true);

      const result = await service.login({ email: 'u1@example.com', password: 'right' }, CTX);
      expect(result).toEqual(TOKENS);
      expect(audit.record).toHaveBeenCalledWith(expect.objectContaining({ action: 'auth.login' }));
    });

    it('rejects a wrong password and audits the failure', async () => {
      const { service, users, passwords, audit } = build();
      users.findByEmail.mockResolvedValue({
        id: 'u1',
        role: UserRole.CLIENT,
        passwordHash: 'hashed',
      });
      passwords.verify.mockResolvedValue(false);

      await expect(
        service.login({ email: 'u1@example.com', password: 'wrong' }, CTX),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      expect(audit.record).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'auth.login_failed' }),
      );
    });

    it('rejects an unknown email without leaking which part failed', async () => {
      const { service, users } = build();
      users.findByEmail.mockResolvedValue(null);
      await expect(
        service.login({ email: 'ghost@example.com', password: 'x' }, CTX),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });
  });

  describe('me', () => {
    it('returns a profile without the password hash', async () => {
      const { service, users } = build();
      users.findById.mockResolvedValue({
        id: 'u1',
        email: 'u1@example.com',
        firstName: 'A',
        lastName: 'B',
        role: UserRole.CLIENT,
        emailVerified: false,
        phoneVerified: false,
        createdAt: new Date(),
        passwordHash: 'secret',
      });
      const profile = await service.me('u1');
      expect(profile).not.toHaveProperty('passwordHash');
      expect(profile.email).toBe('u1@example.com');
    });

    it('throws when the user no longer exists', async () => {
      const { service, users } = build();
      users.findById.mockResolvedValue(null);
      await expect(service.me('gone')).rejects.toBeInstanceOf(UnauthorizedException);
    });
  });
});
