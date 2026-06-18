import { BadRequestException, Injectable } from '@nestjs/common';
import { AuditLogService } from '../../common/audit/audit-log.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AbnValidator } from './abn-validator';
import { AbrService } from './abr.service';
import { AbnStatusDto } from './dto/abn.dto';

/** Context for the audit trail (set by the controller from the request). */
export interface AbnContext {
  ipAddress?: string | null;
  userAgent?: string | null;
}

/**
 * Tasker ABN submission + verification.
 *
 * Flow: validate the checksum locally (cheap, no network), look the ABN up on
 * the ABR for the business name + active status, then persist. The ABN is
 * considered "verified" only when the ABR confirms it is ACTIVE; a missing GUID
 * or an ABR outage stores the ABN as pending (verifiedAt = null) rather than
 * blocking the tasker.
 */
@Injectable()
export class AbnService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly abr: AbrService,
    private readonly audit: AuditLogService,
  ) {}

  async submitAbn(userId: string, rawAbn: string, ctx: AbnContext = {}): Promise<AbnStatusDto> {
    const abn = AbnValidator.normalise(rawAbn);
    if (!AbnValidator.isValid(abn)) {
      throw new BadRequestException('That ABN is not valid. Check the number and try again.');
    }

    const lookup = await this.abr.lookup(abn);
    const verified = lookup?.isActive === true;

    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        abn,
        abrBusinessName: lookup?.businessName ?? null,
        abnVerifiedAt: verified ? new Date() : null,
        noAbnReason: null, // they've provided an ABN; clear any prior "no ABN" note
      },
      select: { abn: true, abrBusinessName: true, abnVerifiedAt: true },
    });

    await this.audit.record({
      actorId: userId,
      action: 'user.abn_submitted',
      resourceType: 'User',
      resourceId: userId,
      // No PII/business name in the audit diff — last 3 digits + outcome only.
      diff: { abnLast3: abn.slice(-3), verified },
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
    });

    return {
      abn: user.abn,
      businessName: user.abrBusinessName,
      verifiedAt: user.abnVerifiedAt,
    };
  }

  async getStatus(userId: string): Promise<AbnStatusDto> {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, deletedAt: null },
      select: { abn: true, abrBusinessName: true, abnVerifiedAt: true },
    });
    return {
      abn: user?.abn ?? null,
      businessName: user?.abrBusinessName ?? null,
      verifiedAt: user?.abnVerifiedAt ?? null,
    };
  }
}
