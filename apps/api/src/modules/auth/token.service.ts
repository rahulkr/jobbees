import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { createId } from '@paralleldrive/cuid2';
import { type UserRole } from '@jobbees/prisma';
import { createHash, randomBytes } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

export interface AccessPayload {
  sub: string;
  role: UserRole;
}

export interface IssueContext {
  userAgent?: string | null;
  ipAddress?: string | null;
}

const REFRESH_TOKEN_BYTES = 32;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

/**
 * Issues + rotates auth tokens.
 *
 * Access: short-lived stateless JWT (signed with JWT_ACCESS_SECRET).
 * Refresh: opaque random token; only its SHA-256 hash is stored (RefreshToken).
 * Rotation: each refresh revokes the presented token and issues a new one,
 * linked via `replacedById`. Presenting an already-revoked token is treated as
 * theft → every active token for that user is revoked (reuse detection).
 */
@Injectable()
export class TokenService {
  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async issueForUser(userId: string, role: UserRole, ctx: IssueContext = {}): Promise<TokenPair> {
    const accessToken = await this.signAccess(userId, role);
    const raw = this.generateRawToken();
    await this.prisma.refreshToken.create({
      data: this.refreshData(createId(), userId, raw, ctx),
    });
    return { accessToken, refreshToken: raw };
  }

  async rotate(presentedRaw: string, ctx: IssueContext = {}): Promise<TokenPair> {
    const existing = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: this.hashToken(presentedRaw) },
    });
    if (!existing) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    if (existing.revokedAt) {
      // Reuse of a rotated token ⇒ likely stolen. Burn the whole session set.
      await this.prisma.refreshToken.updateMany({
        where: { userId: existing.userId, revokedAt: null },
        data: { revokedAt: new Date() },
      });
      throw new UnauthorizedException('Refresh token already used');
    }
    if (existing.expiresAt.getTime() <= Date.now()) {
      throw new UnauthorizedException('Refresh token expired');
    }

    const user = await this.prisma.user.findFirst({
      where: { id: existing.userId, deletedAt: null },
    });
    if (!user) {
      throw new UnauthorizedException('User no longer exists');
    }

    const raw = this.generateRawToken();
    const newId = createId();
    await this.prisma.$transaction([
      this.prisma.refreshToken.create({
        data: this.refreshData(newId, existing.userId, raw, ctx),
      }),
      this.prisma.refreshToken.update({
        where: { id: existing.id },
        data: { revokedAt: new Date(), replacedById: newId },
      }),
    ]);

    const accessToken = await this.signAccess(user.id, user.role);
    return { accessToken, refreshToken: raw };
  }

  /** Idempotent — revokes the presented token if active; no-op otherwise. */
  async revoke(presentedRaw: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { tokenHash: this.hashToken(presentedRaw), revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  verifyAccess(token: string): Promise<AccessPayload> {
    return this.jwt.verifyAsync<AccessPayload>(token, {
      secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'),
    });
  }

  private signAccess(sub: string, role: UserRole): Promise<string> {
    return this.jwt.signAsync(
      { sub, role },
      {
        secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'),
        expiresIn: this.config.get<number>('JWT_ACCESS_TTL_SECONDS', 900),
      },
    );
  }

  private generateRawToken(): string {
    return randomBytes(REFRESH_TOKEN_BYTES).toString('base64url');
  }

  private hashToken(raw: string): string {
    return createHash('sha256').update(raw).digest('hex');
  }

  private refreshData(id: string, userId: string, raw: string, ctx: IssueContext) {
    const days = this.config.get<number>('JWT_REFRESH_TTL_DAYS', 30);
    return {
      id,
      userId,
      tokenHash: this.hashToken(raw),
      expiresAt: new Date(Date.now() + days * MS_PER_DAY),
      userAgent: ctx.userAgent ?? null,
      ipAddress: ctx.ipAddress ?? null,
    };
  }
}
