import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { type User, UserRole } from '@jobbees/prisma';
import { AuditLogService } from '../../common/audit/audit-log.service';
import { UsersService } from '../users/users.service';
import { type SignupDto, type LoginDto, type UserProfileDto } from './dto/auth.dto';
import { PasswordService } from './password.service';
import { type IssueContext, type TokenPair, TokenService } from './token.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UsersService,
    private readonly passwords: PasswordService,
    private readonly tokens: TokenService,
    private readonly audit: AuditLogService,
  ) {}

  async signup(dto: SignupDto, ctx: IssueContext): Promise<TokenPair> {
    const email = dto.email.trim().toLowerCase();
    if (await this.users.findByEmail(email)) {
      throw new ConflictException('Email is already registered');
    }

    const passwordHash = await this.passwords.hash(dto.password);
    const user = await this.users.create({
      email,
      passwordHash,
      firstName: dto.firstName.trim(),
      lastName: dto.lastName.trim(),
      role: dto.role ?? UserRole.CLIENT,
    });

    await this.audit.record({
      actorId: user.id,
      action: 'user.signup',
      resourceType: 'User',
      resourceId: user.id,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
    });

    return this.tokens.issueForUser(user.id, user.role, ctx);
  }

  async login(dto: LoginDto, ctx: IssueContext): Promise<TokenPair> {
    const email = dto.email.trim().toLowerCase();
    const user = await this.users.findByEmail(email);

    // Generic message + no early return shape difference → no user enumeration.
    if (!user?.passwordHash) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const valid = await this.passwords.verify(user.passwordHash, dto.password);
    if (!valid) {
      await this.audit.record({
        actorId: user.id,
        action: 'auth.login_failed',
        resourceType: 'User',
        resourceId: user.id,
        ipAddress: ctx.ipAddress,
        userAgent: ctx.userAgent,
      });
      throw new UnauthorizedException('Invalid email or password');
    }

    await this.audit.record({
      actorId: user.id,
      action: 'auth.login',
      resourceType: 'User',
      resourceId: user.id,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
    });

    return this.tokens.issueForUser(user.id, user.role, ctx);
  }

  refresh(refreshToken: string, ctx: IssueContext): Promise<TokenPair> {
    return this.tokens.rotate(refreshToken, ctx);
  }

  async logout(refreshToken: string): Promise<void> {
    await this.tokens.revoke(refreshToken);
  }

  async me(userId: string): Promise<UserProfileDto> {
    const user = await this.users.findById(userId);
    if (!user) {
      throw new UnauthorizedException('User no longer exists');
    }
    return AuthService.toProfile(user);
  }

  private static toProfile(user: User): UserProfileDto {
    return {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      emailVerified: user.emailVerified,
      phoneVerified: user.phoneVerified,
      createdAt: user.createdAt,
    };
  }
}
