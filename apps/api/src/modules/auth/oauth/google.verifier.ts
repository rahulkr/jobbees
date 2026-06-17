import { Injectable, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import { type OAuthIdentity } from './oauth-identity';

/**
 * Verifies a Google ID token (obtained by the mobile/web client) server-side.
 * The accepted audiences are our OAuth 2.0 client IDs from Google Cloud Console
 * (GOOGLE_OAUTH_CLIENT_IDS) — no Firebase, per ADR 006 (custom-JWT auth).
 */
@Injectable()
export class GoogleVerifier {
  private readonly client = new OAuth2Client();

  constructor(private readonly config: ConfigService) {}

  async verify(idToken: string): Promise<OAuthIdentity> {
    const audience = this.audiences();
    if (audience.length === 0) {
      throw new ServiceUnavailableException('Google sign-in is not configured');
    }

    let payload;
    try {
      const ticket = await this.client.verifyIdToken({ idToken, audience });
      payload = ticket.getPayload();
    } catch {
      throw new UnauthorizedException('Invalid Google token');
    }

    if (!payload?.email) {
      throw new UnauthorizedException('Google token missing email');
    }

    return {
      provider: 'google',
      providerId: payload.sub,
      email: payload.email.toLowerCase(),
      emailVerified: payload.email_verified === true,
      firstName: payload.given_name,
      lastName: payload.family_name,
    };
  }

  private audiences(): string[] {
    return this.config
      .get<string>('GOOGLE_OAUTH_CLIENT_IDS', '')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
  }
}
