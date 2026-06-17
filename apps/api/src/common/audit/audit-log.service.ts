import { Injectable } from '@nestjs/common';
import { createId } from '@paralleldrive/cuid2';
import { Prisma } from '@jobbees/prisma';
import { PrismaService } from '../../prisma/prisma.service';

export interface AuditEntry {
  /** Who did it (null for anonymous/self-serve actions like signup). */
  actorId?: string | null;
  /** Dotted action name, e.g. "auth.login", "user.signup". */
  action: string;
  resourceType: string;
  resourceId: string;
  diff?: Record<string, unknown>;
  ipAddress?: string | null;
  userAgent?: string | null;
}

/**
 * Append-only audit trail. Every sensitive state transition writes one row
 * (CLAUDE.md rule 7); the table is DB-protected against UPDATE/DELETE.
 * Never include secrets/PII in `diff`.
 */
@Injectable()
export class AuditLogService {
  constructor(private readonly prisma: PrismaService) {}

  async record(entry: AuditEntry): Promise<void> {
    await this.prisma.auditLog.create({
      data: {
        id: createId(),
        actorId: entry.actorId ?? null,
        action: entry.action,
        resourceType: entry.resourceType,
        resourceId: entry.resourceId,
        diffJson: entry.diff as Prisma.InputJsonValue | undefined,
        ipAddress: entry.ipAddress ?? null,
        userAgent: entry.userAgent ?? null,
      },
    });
  }
}
