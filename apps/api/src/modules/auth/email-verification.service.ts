import { Injectable, UnauthorizedException } from '@nestjs/common';
import { createId } from '@paralleldrive/cuid2';
import { AuditLogService } from '../../common/audit/audit-log.service';
import { PrismaService } from '../../prisma/prisma.service';
import { MailService } from './mail/mail.service';
import { generateRawToken, hashToken } from './token-hash.util';

const TOKEN_TTL_MS = 24 * 60 * 60 * 1000; // 24h

@Injectable()
export class EmailVerificationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mail: MailService,
    private readonly audit: AuditLogService,
  ) {}

  /** Issues a fresh verification token and emails the link. */
  async issue(userId: string, email: string): Promise<void> {
    const raw = generateRawToken();
    await this.prisma.emailVerificationToken.create({
      data: {
        id: createId(),
        userId,
        tokenHash: hashToken(raw),
        expiresAt: new Date(Date.now() + TOKEN_TTL_MS),
      },
    });
    await this.mail.sendEmailVerification(email, raw);
  }

  async verify(rawToken: string): Promise<void> {
    const token = await this.prisma.emailVerificationToken.findUnique({
      where: { tokenHash: hashToken(rawToken) },
    });
    if (!token || token.usedAt || token.expiresAt.getTime() <= Date.now()) {
      throw new UnauthorizedException('Invalid or expired verification token');
    }

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: token.userId },
        data: { emailVerified: true },
      }),
      this.prisma.emailVerificationToken.update({
        where: { id: token.id },
        data: { usedAt: new Date() },
      }),
    ]);

    await this.audit.record({
      actorId: token.userId,
      action: 'user.email_verified',
      resourceType: 'User',
      resourceId: token.userId,
    });
  }

  /** Invalidate outstanding tokens, then issue a fresh one. */
  async resend(userId: string, email: string): Promise<void> {
    await this.prisma.emailVerificationToken.updateMany({
      where: { userId, usedAt: null },
      data: { usedAt: new Date() },
    });
    await this.issue(userId, email);
  }
}
