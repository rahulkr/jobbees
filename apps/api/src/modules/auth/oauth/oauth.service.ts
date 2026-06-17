import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { UserRole } from '@jobbees/prisma';
import { AuditLogService } from '../../../common/audit/audit-log.service';
import { UsersService } from '../../users/users.service';
import { type OAuthLoginDto } from '../dto/oauth.dto';
import { type IssueContext, type TokenPair, TokenService } from '../token.service';
import { AppleVerifier } from './apple.verifier';
import { GoogleVerifier } from './google.verifier';
import { type OAuthIdentity } from './oauth-identity';

/**
 * Social login: verify the provider ID token, upsert the user by verified
 * email, and issue our own JWT pair (ADR 006 — we are the identity authority,
 * the provider just attests the email). Account linking is by verified email.
 */
@Injectable()
export class OAuthService {
  constructor(
    private readonly google: GoogleVerifier,
    private readonly apple: AppleVerifier,
    private readonly users: UsersService,
    private readonly tokens: TokenService,
    private readonly audit: AuditLogService,
  ) {}

  async login(provider: string, dto: OAuthLoginDto, ctx: IssueContext): Promise<TokenPair> {
    const identity = await this.verify(provider, dto.idToken);

    // Only ever link/create on a provider-verified email (anti-takeover).
    if (!identity.emailVerified) {
      throw new UnauthorizedException('Provider email is not verified');
    }

    let user = await this.users.findByEmail(identity.email);
    const isNew = !user;
    if (!user) {
      user = await this.users.createOAuthUser({
        email: identity.email,
        firstName: (identity.firstName ?? dto.firstName ?? '').trim(),
        lastName: (identity.lastName ?? dto.lastName ?? '').trim(),
        role: dto.role ?? UserRole.CLIENT,
        emailVerified: true,
      });
    }

    await this.audit.record({
      actorId: user.id,
      action: isNew
        ? `user.signup_oauth.${identity.provider}`
        : `auth.oauth_login.${identity.provider}`,
      resourceType: 'User',
      resourceId: user.id,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
    });

    return this.tokens.issueForUser(user.id, user.role, ctx);
  }

  private verify(provider: string, idToken: string): Promise<OAuthIdentity> {
    switch (provider) {
      case 'google':
        return this.google.verify(idToken);
      case 'apple':
        return this.apple.verify(idToken);
      default:
        throw new BadRequestException(`Unsupported OAuth provider: ${provider}`);
    }
  }
}
