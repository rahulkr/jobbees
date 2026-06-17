import { UnauthorizedException } from '@nestjs/common';
import { AuditLogService } from '../../common/audit/audit-log.service';
import { PrismaService } from '../../prisma/prisma.service';
import { MailService } from './mail/mail.service';
import { EmailVerificationService } from './email-verification.service';

function build() {
  const prisma = {
    emailVerificationToken: {
      create: jest.fn().mockResolvedValue({}),
      findUnique: jest.fn(),
      update: jest.fn().mockResolvedValue({}),
      updateMany: jest.fn().mockResolvedValue({ count: 0 }),
    },
    user: { update: jest.fn().mockResolvedValue({}) },
    $transaction: jest.fn().mockResolvedValue([]),
  };
  const mail = {
    sendEmailVerification: jest.fn().mockResolvedValue(undefined),
    sendPasswordReset: jest.fn(),
  };
  const audit = { record: jest.fn().mockResolvedValue(undefined) };
  const service = new EmailVerificationService(
    prisma as unknown as PrismaService,
    mail as unknown as MailService,
    audit as unknown as AuditLogService,
  );
  return { service, prisma, mail, audit };
}

const future = () => new Date(Date.now() + 60 * 60 * 1000);
const past = () => new Date(Date.now() - 1000);

describe('EmailVerificationService', () => {
  it('issue persists a token + sends the email', async () => {
    const { service, prisma, mail } = build();
    await service.issue('u1', 'a@example.com');
    expect(prisma.emailVerificationToken.create).toHaveBeenCalledTimes(1);
    expect(mail.sendEmailVerification).toHaveBeenCalledWith('a@example.com', expect.any(String));
  });

  it('verify marks email verified + audits on a valid token', async () => {
    const { service, prisma, audit } = build();
    prisma.emailVerificationToken.findUnique.mockResolvedValue({
      id: 't1',
      userId: 'u1',
      usedAt: null,
      expiresAt: future(),
    });
    await service.verify('raw');
    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    expect(audit.record).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'user.email_verified' }),
    );
  });

  it('rejects unknown / used / expired tokens', async () => {
    const { service, prisma } = build();
    prisma.emailVerificationToken.findUnique.mockResolvedValueOnce(null);
    await expect(service.verify('x')).rejects.toBeInstanceOf(UnauthorizedException);

    prisma.emailVerificationToken.findUnique.mockResolvedValueOnce({
      id: 't1',
      userId: 'u1',
      usedAt: new Date(),
      expiresAt: future(),
    });
    await expect(service.verify('x')).rejects.toBeInstanceOf(UnauthorizedException);

    prisma.emailVerificationToken.findUnique.mockResolvedValueOnce({
      id: 't1',
      userId: 'u1',
      usedAt: null,
      expiresAt: past(),
    });
    await expect(service.verify('x')).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
