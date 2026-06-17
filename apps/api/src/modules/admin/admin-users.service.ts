import { Injectable, NotFoundException } from '@nestjs/common';
import { AuditLogService } from '../../common/audit/audit-log.service';
import { PrismaService } from '../../prisma/prisma.service';

interface ActorContext {
  ipAddress?: string | null;
  userAgent?: string | null;
}

@Injectable()
export class AdminUsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditLogService,
  ) {}

  /** Suspend a user: set the flag, revoke all sessions, audit. */
  async suspend(
    actorId: string,
    userId: string,
    reason: string | undefined,
    ctx: ActorContext,
  ): Promise<void> {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, deletedAt: null },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: { suspendedAt: new Date(), suspensionReason: reason ?? null },
      }),
      this.prisma.refreshToken.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: new Date() },
      }),
    ]);

    await this.audit.record({
      actorId,
      action: 'user.suspended',
      resourceType: 'User',
      resourceId: userId,
      diff: { reason: reason ?? null },
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
    });
  }

  async reinstate(actorId: string, userId: string, ctx: ActorContext): Promise<void> {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, deletedAt: null },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: { suspendedAt: null, suspensionReason: null },
    });

    await this.audit.record({
      actorId,
      action: 'user.reinstated',
      resourceType: 'User',
      resourceId: userId,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
    });
  }
}
