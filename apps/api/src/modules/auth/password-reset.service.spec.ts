import { UnauthorizedException } from '@nestjs/common';
import { AuditLogService } from '../../common/audit/audit-log.service';
import { PrismaService } from '../../prisma/prisma.service';
import { LockoutService } from './lockout.service';
import { MailService } from './mail/mail.service';
import { PasswordService } from './password.service';
import { PasswordResetService } from './password-reset.service';

function build() {
  const prisma = {
    user: { findFirst: jest.fn(), update: jest.fn().mockResolvedValue({}) },
    passwordResetToken: {
      create: jest.fn().mockResolvedValue({}),
      findUnique: jest.fn(),
      update: jest.fn().mockResolvedValue({}),
    },
    refreshToken: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
    $transaction: jest.fn().mockResolvedValue([]),
  };
  const mail = {
    sendEmailVerification: jest.fn(),
    sendPasswordReset: jest.fn().mockResolvedValue(undefined),
  };
  const passwords = { hash: jest.fn().mockResolvedValue('new-hash'), verify: jest.fn() };
  const lockout = { clearLogin: jest.fn().mockResolvedValue(undefined) };
  const audit = { record: jest.fn().mockResolvedValue(undefined) };
  const service = new PasswordResetService(
    prisma as unknown as PrismaService,
    mail as unknown as MailService,
    passwords as unknown as PasswordService,
    lockout as unknown as LockoutService,
    audit as unknown as AuditLogService,
  );
  return { service, prisma, mail, passwords, lockout, audit };
}

const future = () => new Date(Date.now() + 60 * 60 * 1000);

describe('PasswordResetService', () => {
  describe('forgot', () => {
    it('stays silent for an unknown email (no enumeration)', async () => {
      const { service, prisma, mail } = build();
      prisma.user.findFirst.mockResolvedValue(null);
      await service.forgot('ghost@example.com');
      expect(prisma.passwordResetToken.create).not.toHaveBeenCalled();
      expect(mail.sendPasswordReset).not.toHaveBeenCalled();
    });

    it('issues a token + emails it for a known user', async () => {
      const { service, prisma, mail } = build();
      prisma.user.findFirst.mockResolvedValue({ id: 'u1', email: 'a@example.com' });
      await service.forgot('A@Example.com');
      expect(prisma.passwordResetToken.create).toHaveBeenCalledTimes(1);
      expect(mail.sendPasswordReset).toHaveBeenCalledWith('a@example.com', expect.any(String));
    });
  });

  describe('reset', () => {
    it('rehashes, marks used, revokes sessions, clears lockout', async () => {
      const { service, prisma, passwords, lockout } = build();
      prisma.passwordResetToken.findUnique.mockResolvedValue({
        id: 't1',
        userId: 'u1',
        usedAt: null,
        expiresAt: future(),
      });
      prisma.user.findFirst.mockResolvedValue({ id: 'u1', email: 'a@example.com' });

      await service.reset('raw', 'a-new-strong-passphrase');

      expect(passwords.hash).toHaveBeenCalledWith('a-new-strong-passphrase');
      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
      expect(lockout.clearLogin).toHaveBeenCalledWith('a@example.com');
    });

    it('rejects an invalid token', async () => {
      const { service, prisma } = build();
      prisma.passwordResetToken.findUnique.mockResolvedValue(null);
      await expect(service.reset('x', 'a-new-strong-passphrase')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });
  });
});
