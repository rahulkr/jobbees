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

describe('UsersService tasker profile', () => {
  function buildProfile() {
    const tx = {
      user: { update: jest.fn().mockResolvedValue({}) },
      userSkill: {
        deleteMany: jest.fn().mockResolvedValue({}),
        createMany: jest.fn().mockResolvedValue({}),
      },
    };
    const prisma = {
      user: {
        findFirst: jest.fn(),
      },
      $transaction: jest.fn(async (cb: (t: typeof tx) => Promise<void>) => cb(tx)),
    };
    const audit = { record: jest.fn().mockResolvedValue(undefined) };
    const service = new UsersService(
      prisma as unknown as PrismaService,
      audit as unknown as AuditLogService,
    );
    return { service, prisma, tx };
  }

  it('returns the profile with skills flattened', async () => {
    const { service, prisma } = buildProfile();
    prisma.user.findFirst.mockResolvedValue({
      bio: 'Handy',
      hourlyRateCents: 8500,
      skills: [{ skill: 'plumbing' }, { skill: 'tiling' }],
    });

    const profile = await service.getTaskerProfile('u1');

    expect(profile).toEqual({
      bio: 'Handy',
      hourlyRateCents: 8500,
      skills: ['plumbing', 'tiling'],
    });
  });

  it('updates fields and replaces skills (deduped) in one transaction', async () => {
    const { service, prisma, tx } = buildProfile();
    // findById (exists) then getTaskerProfile read-back.
    prisma.user.findFirst
      .mockResolvedValueOnce({ id: 'u1', role: UserRole.TASKER })
      .mockResolvedValueOnce({
        bio: 'New bio',
        hourlyRateCents: 9000,
        skills: [{ skill: 'plumbing' }],
      });

    await service.updateTaskerProfile('u1', {
      bio: 'New bio',
      hourlyRateCents: 9000,
      skills: ['plumbing', 'plumbing', '  ', 'tiling'],
    });

    expect(tx.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { bio: 'New bio', hourlyRateCents: 9000 },
      }),
    );
    expect(tx.userSkill.deleteMany).toHaveBeenCalledWith({ where: { userId: 'u1' } });
    expect(tx.userSkill.createMany).toHaveBeenCalledWith({
      data: [
        { userId: 'u1', skill: 'plumbing' },
        { userId: 'u1', skill: 'tiling' },
      ],
    });
  });

  it('throws when updating a missing user', async () => {
    const { service, prisma } = buildProfile();
    prisma.user.findFirst.mockResolvedValue(null);

    await expect(service.updateTaskerProfile('ghost', { bio: 'x' })).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
