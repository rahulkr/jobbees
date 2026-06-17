import { Injectable, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createRemoteJWKSet, jwtVerify } from 'jose';
import { type OAuthIdentity } from './oauth-identity';

const APPLE_ISSUER = 'https://appleid.apple.com';
const APPLE_JWKS_URL = new URL('https://appleid.apple.com/auth/keys');

/**
 * Verifies an Apple ID token against Apple's JWKS. Accepted audiences are our
 * Apple client IDs (APPLE_CLIENT_IDS) — the app bundle id `com.seaford.jobbees`
 * for native sign-in, plus any Services ID for web.
 *
 * Apple omits the user's name from the ID token (it's sent to the client only
 * on first authorization), so the client passes name in the request body.
 */
@Injectable()
export class AppleVerifier {
  // jose caches the remote key set and handles key rotation.
  private readonly jwks = createRemoteJWKSet(APPLE_JWKS_URL);

  constructor(private readonly config: ConfigService) {}

  async verify(idToken: string): Promise<OAuthIdentity> {
    const audience = this.audiences();
    if (audience.length === 0) {
      throw new ServiceUnavailableException('Apple sign-in is not configured');
    }

    let payload;
    try {
      ({ payload } = await jwtVerify(idToken, this.jwks, {
        issuer: APPLE_ISSUER,
        audience,
      }));
    } catch {
      throw new UnauthorizedException('Invalid Apple token');
    }

    const email = typeof payload.email === 'string' ? payload.email.toLowerCase() : undefined;
    if (!email) {
      throw new UnauthorizedException('Apple token missing email');
    }

    return {
      provider: 'apple',
      providerId: String(payload.sub),
      email,
      // Apple returns email_verified as a boolean or the string "true".
      emailVerified: payload.email_verified === true || payload.email_verified === 'true',
    };
  }

  private audiences(): string[] {
    return this.config
      .get<string>('APPLE_CLIENT_IDS', '')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
  }
}
