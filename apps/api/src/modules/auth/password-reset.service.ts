import { Injectable, UnauthorizedException } from '@nestjs/common';
import { createId } from '@paralleldrive/cuid2';
import { AuditLogService } from '../../common/audit/audit-log.service';
import { PrismaService } from '../../prisma/prisma.service';
import { LockoutService } from './lockout.service';
import { MailService } from './mail/mail.service';
import { PasswordService } from './password.service';
import { generateRawToken, hashToken } from './token-hash.util';

const TOKEN_TTL_MS = 60 * 60 * 1000; // 1h

@Injectable()
export class PasswordResetService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mail: MailService,
    private readonly passwords: PasswordService,
    private readonly lockout: LockoutService,
    private readonly audit: AuditLogService,
  ) {}

  /** Always resolves — never reveals whether the email exists (no enumeration). */
  async forgot(email: string): Promise<void> {
    const normalized = email.trim().toLowerCase();
    const user = await this.prisma.user.findFirst({
      where: { email: normalized, deletedAt: null },
    });
    if (!user) {
      return;
    }

    const raw = generateRawToken();
    await this.prisma.passwordResetToken.create({
      data: {
        id: createId(),
        userId: user.id,
        tokenHash: hashToken(raw),
        expiresAt: new Date(Date.now() + TOKEN_TTL_MS),
      },
    });
    await this.mail.sendPasswordReset(user.email, raw);
    await this.audit.record({
      actorId: user.id,
      action: 'auth.password_reset_requested',
      resourceType: 'User',
      resourceId: user.id,
    });
  }

  async reset(rawToken: string, newPassword: string): Promise<void> {
    const token = await this.prisma.passwordResetToken.findUnique({
      where: { tokenHash: hashToken(rawToken) },
    });
    if (!token || token.usedAt || token.expiresAt.getTime() <= Date.now()) {
      throw new UnauthorizedException('Invalid or expired reset token');
    }

    const user = await this.prisma.user.findFirst({
      where: { id: token.userId, deletedAt: null },
    });
    if (!user) {
      throw new UnauthorizedException('User no longer exists');
    }

    const passwordHash = await this.passwords.hash(newPassword);
    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: user.id },
        data: { passwordHash },
      }),
      this.prisma.passwordResetToken.update({
        where: { id: token.id },
        data: { usedAt: new Date() },
      }),
      // Sessions must not outlive a password change (security-review §B5).
      this.prisma.refreshToken.updateMany({
        where: { userId: user.id, revokedAt: null },
        data: { revokedAt: new Date() },
      }),
    ]);

    // Let them log in again after a lockout-driven reset.
    await this.lockout.clearLogin(user.email);
    await this.audit.record({
      actorId: user.id,
      action: 'auth.password_reset',
      resourceType: 'User',
      resourceId: user.id,
    });
  }
}
