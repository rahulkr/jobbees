import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { UserRole } from '@jobbees/prisma';
import type { AuditLogService } from '../../common/audit/audit-log.service';
import type { PrismaService } from '../../prisma/prisma.service';
import { UsersService } from './users.service';

function build(existing: { id: string; role: UserRole } | null) {
  const prisma = {
    user: {
      findFirst: jest.fn().mockResolvedValue(existing),
      update: jest.fn().mockImplementation(({ data }) => Promise.resolve({ ...existing, ...data })),
    },
  };
  const audit = { record: jest.fn().mockResolvedValue(undefined) };
  const service = new UsersService(
    prisma as unknown as PrismaService,
    audit as unknown as AuditLogService,
  );
  return { service, prisma, audit };
}

describe('UsersService.becomeTasker', () => {
  it('upgrades a client to a tasker and writes an audit row', async () => {
    const { service, prisma, audit } = build({
      id: 'u1',
      role: UserRole.CLIENT,
    });

    const result = await service.becomeTasker('u1', { ipAddress: '1.2.3.4' });

    expect(result.role).toBe(UserRole.TASKER);
    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { role: UserRole.TASKER } }),
    );
    expect(audit.record).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'user.became_tasker',
        resourceType: 'User',
        resourceId: 'u1',
        diff: { from: UserRole.CLIENT, to: UserRole.TASKER },
      }),
    );
  });

  it('is an idempotent no-op for an existing tasker', async () => {
    const { service, prisma, audit } = build({
      id: 'u1',
      role: UserRole.TASKER,
    });

    const result = await service.becomeTasker('u1');

    expect(result.role).toBe(UserRole.TASKER);
    expect(prisma.user.update).not.toHaveBeenCalled();
    expect(audit.record).not.toHaveBeenCalled();
  });

  it('refuses to re-role an admin', async () => {
    const { service, prisma, audit } = build({
      id: 'a1',
      role: UserRole.ADMIN,
    });

    await expect(service.becomeTasker('a1')).rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.user.update).not.toHaveBeenCalled();
    expect(audit.record).not.toHaveBeenCalled();
  });

  it('throws when the user does not exist', async () => {
    const { service } = build(null);

    await expect(service.becomeTasker('ghost')).rejects.toBeInstanceOf(NotFoundException);
  });
});
