export type OAuthProviderName = 'google' | 'apple';

/** Normalised identity extracted from a verified provider ID token. */
export interface OAuthIdentity {
  provider: OAuthProviderName;
  providerId: string;
  email: string;
  emailVerified: boolean;
  firstName?: string;
  lastName?: string;
}
