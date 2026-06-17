import { NotFoundException } from '@nestjs/common';
import { AuditLogService } from '../../common/audit/audit-log.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminUsersService } from './admin-users.service';

function build() {
  const prisma = {
    user: { findFirst: jest.fn(), update: jest.fn().mockResolvedValue({}) },
    refreshToken: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
    $transaction: jest.fn().mockResolvedValue([]),
  };
  const audit = { record: jest.fn().mockResolvedValue(undefined) };
  const service = new AdminUsersService(
    prisma as unknown as PrismaService,
    audit as unknown as AuditLogService,
  );
  return { service, prisma, audit };
}

const CTX = { ipAddress: '1.2.3.4', userAgent: 'jest' };

describe('AdminUsersService', () => {
  it('suspend sets the flag, revokes sessions, and audits', async () => {
    const { service, prisma, audit } = build();
    prisma.user.findFirst.mockResolvedValue({ id: 'u1' });
    await service.suspend('admin1', 'u1', 'spam', CTX);
    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    expect(audit.record).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'user.suspended', actorId: 'admin1' }),
    );
  });

  it('suspend throws 404 for an unknown user', async () => {
    const { service, prisma } = build();
    prisma.user.findFirst.mockResolvedValue(null);
    await expect(service.suspend('admin1', 'missing', undefined, CTX)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('reinstate clears the flag + audits', async () => {
    const { service, prisma, audit } = build();
    prisma.user.findFirst.mockResolvedValue({ id: 'u1' });
    await service.reinstate('admin1', 'u1', CTX);
    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { suspendedAt: null, suspensionReason: null },
      }),
    );
    expect(audit.record).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'user.reinstated' }),
    );
  });
});
