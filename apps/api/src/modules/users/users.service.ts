import { ConflictException, Injectable } from '@nestjs/common';
import { createId } from '@paralleldrive/cuid2';
import { type User, type UserRole } from '@jobbees/prisma';
import { PrismaService } from '../../prisma/prisma.service';

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

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

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
