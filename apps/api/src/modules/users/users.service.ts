import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { createId } from '@paralleldrive/cuid2';
import { type User, UserRole } from '@jobbees/prisma';
import { AuditLogService } from '../../common/audit/audit-log.service';
import { PrismaService } from '../../prisma/prisma.service';

/** Request context for the audit trail (set by the controller). */
export interface ActorContext {
  ipAddress?: string | null;
  userAgent?: string | null;
}

export interface CreateUserInput {
  email: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  role: UserRole;
}

export interface CreateOAuthUserInput {
  email: string;
  firstName: string;
  lastName: string;
  role: UserRole;
  emailVerified: boolean;
}

export interface TaskerProfile {
  bio: string | null;
  hourlyRateCents: number | null;
  skills: string[];
}

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditLogService,
  ) {}

  /** Soft-delete aware lookups (CLAUDE.md rule 10). */
  findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findFirst({ where: { email, deletedAt: null } });
  }

  findById(id: string): Promise<User | null> {
    return this.prisma.user.findFirst({ where: { id, deletedAt: null } });
  }

  create(input: CreateUserInput): Promise<User> {
    return this.prisma.user.create({
      data: {
        id: createId(),
        email: input.email,
        passwordHash: input.passwordHash,
        firstName: input.firstName,
        lastName: input.lastName,
        role: input.role,
        // countryCode defaults to "AU" in the schema.
      },
    });
  }

  /** Creates a social-login user (no password — OAuth only). */
  createOAuthUser(input: CreateOAuthUserInput): Promise<User> {
    return this.prisma.user.create({
      data: {
        id: createId(),
        email: input.email,
        firstName: input.firstName,
        lastName: input.lastName,
        role: input.role,
        emailVerified: input.emailVerified,
        passwordHash: null,
      },
    });
  }

  /**
   * Upgrades a client to a tasker. One-way (CLAUDE.md role model): a tasker can
   * also act as a client, but a client only becomes a tasker through this gated
   * step. Idempotent — an existing tasker is returned unchanged so retries (and
   * stale CLIENT access tokens that haven't refreshed yet) are safe. Admins are
   * never re-roled here.
   *
   * The caller must refresh the access token afterwards: the role is baked into
   * the JWT, so TASKER-only endpoints (e.g. ABN) keep rejecting until rotation
   * re-reads the new role from the DB.
   */
  async becomeTasker(userId: string, ctx: ActorContext = {}): Promise<User> {
    const user = await this.findById(userId);
    if (!user) throw new NotFoundException('User not found');
    if (user.role === UserRole.TASKER) return user; // idempotent no-op
    if (user.role !== UserRole.CLIENT) {
      throw new ForbiddenException('Only clients can become taskers');
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { role: UserRole.TASKER },
    });

    await this.audit.record({
      actorId: userId,
      action: 'user.became_tasker',
      resourceType: 'User',
      resourceId: userId,
      diff: { from: UserRole.CLIENT, to: UserRole.TASKER },
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
    });

    return updated;
  }

  /** The tasker profile (bio, hourly rate, free-text skill tags). */
  async getTaskerProfile(userId: string): Promise<TaskerProfile> {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, deletedAt: null },
      select: {
        bio: true,
        hourlyRateCents: true,
        skills: { select: { skill: true } },
      },
    });
    if (!user) throw new NotFoundException('User not found');
    return {
      bio: user.bio,
      hourlyRateCents: user.hourlyRateCents,
      skills: user.skills.map((s) => s.skill),
    };
  }

  /**
   * Partial update of the tasker profile. Only provided fields change; `skills`
   * (when given) replaces the whole set. The user row + skill rows update in one
   * transaction so a half-written profile is never observable.
   */
  async updateTaskerProfile(
    userId: string,
    input: { bio?: string; hourlyRateCents?: number; skills?: string[] },
  ): Promise<TaskerProfile> {
    const user = await this.findById(userId);
    if (!user) throw new NotFoundException('User not found');

    await this.prisma.$transaction(async (tx) => {
      if (input.bio !== undefined || input.hourlyRateCents !== undefined) {
        await tx.user.update({
          where: { id: userId },
          data: {
            ...(input.bio !== undefined ? { bio: input.bio } : {}),
            ...(input.hourlyRateCents !== undefined
              ? { hourlyRateCents: input.hourlyRateCents }
              : {}),
          },
        });
      }
      if (input.skills !== undefined) {
        const unique = [...new Set(input.skills.map((s) => s.trim()))].filter((s) => s.length > 0);
        await tx.userSkill.deleteMany({ where: { userId } });
        if (unique.length > 0) {
          await tx.userSkill.createMany({
            data: unique.map((skill) => ({ userId, skill })),
          });
        }
      }
    });

    return this.getTaskerProfile(userId);
  }

  /** Sets the phone + marks it verified. Phone is unique — reject if taken. */
  async markPhoneVerified(userId: string, phone: string): Promise<User> {
    const owner = await this.prisma.user.findFirst({
      where: { phone, deletedAt: null },
    });
    if (owner && owner.id !== userId) {
      throw new ConflictException('Phone number already in use');
    }
    return this.prisma.user.update({
      where: { id: userId },
      data: { phone, phoneVerified: true },
    });
  }
}
