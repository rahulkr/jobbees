import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  HttpException,
  UnauthorizedException,
} from '@nestjs/common';
import { UserRole } from '@jobbees/prisma';
import { AuditLogService } from '../../common/audit/audit-log.service';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';
import { EmailVerificationService } from './email-verification.service';
import { LockoutService } from './lockout.service';
import { OtpService } from './otp/otp.service';
import { ReauthService } from './reauth.service';
import { PasswordService } from './password.service';
import { TokenService } from './token.service';

const TOKENS = { accessToken: 'a', refreshToken: 'r' };
const CTX = { ipAddress: '127.0.0.1', userAgent: 'jest' };

function build() {
  const users = {
    findByEmail: jest.fn(),
    findById: jest.fn(),
    create: jest.fn(),
    markPhoneVerified: jest.fn().mockResolvedValue({}),
  };
  const passwords = { hash: jest.fn(), verify: jest.fn() };
  const tokens = {
    issueForUser: jest.fn().mockResolvedValue(TOKENS),
    rotate: jest.fn(),
    revoke: jest.fn(),
    revokeAllForUser: jest.fn().mockResolvedValue(undefined),
  };
  const audit = { record: jest.fn().mockResolvedValue(undefined) };
  const lockout = {
    isLoginLocked: jest.fn().mockResolvedValue(false),
    recordFailedLogin: jest.fn().mockResolvedValue({ locked: false }),
    clearLogin: jest.fn().mockResolvedValue(undefined),
    isOtpLocked: jest.fn().mockResolvedValue(false),
    recordFailedOtp: jest.fn().mockResolvedValue({ locked: false }),
    clearOtp: jest.fn().mockResolvedValue(undefined),
  };
  const otp = {
    send: jest.fn().mockResolvedValue(undefined),
    verify: jest.fn(),
  };
  const emailVerification = { issue: jest.fn().mockResolvedValue(undefined) };
  const reauthService = { grant: jest.fn().mockResolvedValue(300), isRecent: jest.fn() };
  const service = new AuthService(
    users as unknown as UsersService,
    passwords as unknown as PasswordService,
    tokens as unknown as TokenService,
    audit as unknown as AuditLogService,
    lockout as unknown as LockoutService,
    otp as unknown as OtpService,
    emailVerification as unknown as EmailVerificationService,
    reauthService as unknown as ReauthService,
  );
  return {
    service,
    users,
    passwords,
    tokens,
    audit,
    lockout,
    otp,
    emailVerification,
    reauthService,
  };
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

    it('rejects a suspended user (403) even with the right password', async () => {
      const { service, users, passwords } = build();
      users.findByEmail.mockResolvedValue({
        id: 'u1',
        role: UserRole.CLIENT,
        passwordHash: 'hashed',
        suspendedAt: new Date(),
      });
      passwords.verify.mockResolvedValue(true);
      const error = await service
        .login({ email: 'u1@example.com', password: 'right' }, CTX)
        .catch((e: unknown) => e);
      expect(error).toBeInstanceOf(ForbiddenException);
      // Carries the machine-readable code the mobile app routes the
      // account-suspended screen on (not just the human message).
      expect((error as ForbiddenException).getResponse()).toMatchObject({
        code: 'ACCOUNT_SUSPENDED',
      });
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

  describe('lockout', () => {
    it('blocks login (429) when the account is locked', async () => {
      const { service, lockout, users } = build();
      lockout.isLoginLocked.mockResolvedValue(true);
      await expect(
        service.login({ email: 'u1@example.com', password: 'x' }, CTX),
      ).rejects.toBeInstanceOf(HttpException);
      expect(users.findByEmail).not.toHaveBeenCalled();
    });

    it('records a failed login on wrong password', async () => {
      const { service, users, passwords, lockout } = build();
      users.findByEmail.mockResolvedValue({
        id: 'u1',
        role: UserRole.CLIENT,
        passwordHash: 'hashed',
      });
      passwords.verify.mockResolvedValue(false);
      await expect(
        service.login({ email: 'u1@example.com', password: 'wrong' }, CTX),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      expect(lockout.recordFailedLogin).toHaveBeenCalledWith('u1@example.com', CTX);
    });

    it('clears the counter on successful login', async () => {
      const { service, users, passwords, lockout } = build();
      users.findByEmail.mockResolvedValue({
        id: 'u1',
        role: UserRole.CLIENT,
        passwordHash: 'hashed',
      });
      passwords.verify.mockResolvedValue(true);
      await service.login({ email: 'u1@example.com', password: 'right' }, CTX);
      expect(lockout.clearLogin).toHaveBeenCalledWith('u1@example.com');
    });
  });

  describe('phone OTP', () => {
    it('verifies + marks the phone verified on the magic code', async () => {
      const { service, otp, users, lockout } = build();
      otp.verify.mockResolvedValue(true);
      const res = await service.verifyPhoneOtp('u1', '+61400000000', '000000');
      expect(res).toEqual({ phoneVerified: true });
      expect(users.markPhoneVerified).toHaveBeenCalledWith('u1', '+61400000000');
      expect(lockout.clearOtp).toHaveBeenCalledWith('u1');
    });

    it('records a failed OTP and rejects a wrong code', async () => {
      const { service, otp, lockout } = build();
      otp.verify.mockResolvedValue(false);
      await expect(service.verifyPhoneOtp('u1', '+61400000000', '111111')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      expect(lockout.recordFailedOtp).toHaveBeenCalled();
    });

    it('blocks OTP verify (429) when OTP-locked', async () => {
      const { service, lockout, otp } = build();
      lockout.isOtpLocked.mockResolvedValue(true);
      await expect(service.verifyPhoneOtp('u1', '+61400000000', '000000')).rejects.toBeInstanceOf(
        HttpException,
      );
      expect(otp.verify).not.toHaveBeenCalled();
    });
  });

  describe('session security', () => {
    it('logoutAll revokes every session + audits', async () => {
      const { service, tokens, audit } = build();
      await service.logoutAll('u1', CTX);
      expect(tokens.revokeAllForUser).toHaveBeenCalledWith('u1');
      expect(audit.record).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'auth.logout_all' }),
      );
    });

    it('reauth grants a window on the correct password', async () => {
      const { service, users, passwords, reauthService } = build();
      users.findById.mockResolvedValue({ id: 'u1', passwordHash: 'hashed' });
      passwords.verify.mockResolvedValue(true);
      await expect(service.reauth('u1', 'right', CTX)).resolves.toEqual({
        validForSeconds: 300,
      });
      expect(reauthService.grant).toHaveBeenCalledWith('u1');
    });

    it('reauth rejects a wrong password', async () => {
      const { service, users, passwords, reauthService } = build();
      users.findById.mockResolvedValue({ id: 'u1', passwordHash: 'hashed' });
      passwords.verify.mockResolvedValue(false);
      await expect(service.reauth('u1', 'wrong', CTX)).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      expect(reauthService.grant).not.toHaveBeenCalled();
    });

    it('reauth is unavailable for a password-less (social) account', async () => {
      const { service, users } = build();
      users.findById.mockResolvedValue({ id: 'u1', passwordHash: null });
      await expect(service.reauth('u1', 'x', CTX)).rejects.toBeInstanceOf(BadRequestException);
    });
  });
});
