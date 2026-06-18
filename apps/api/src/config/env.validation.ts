import { plainToInstance, Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
  MinLength,
  validateSync,
} from 'class-validator';

/**
 * Typed, validated environment configuration.
 *
 * Validated once at boot (see `validateEnv`); if anything required is missing
 * or malformed the app refuses to start rather than failing later at runtime.
 * Access values via `ConfigService`, never `process.env` directly (CLAUDE.md).
 */
export enum NodeEnv {
  Development = 'development',
  Test = 'test',
  Production = 'production',
}

export enum OtpProvider {
  Mock = 'mock',
  Firebase = 'firebase',
  Notifyre = 'notifyre',
  Twilio = 'twilio',
}

export class EnvironmentVariables {
  @IsEnum(NodeEnv)
  @IsOptional()
  NODE_ENV: NodeEnv = NodeEnv.Development;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(65535)
  @IsOptional()
  PORT = 3000;

  @IsString()
  DATABASE_URL!: string;

  @IsString()
  @IsOptional()
  REDIS_URL = 'redis://localhost:6379';

  // Signs short-lived access JWTs. Required — no insecure default (prod injects
  // a real secret via Key Vault; dev sets it in .env.local).
  @IsString()
  @MinLength(32)
  JWT_ACCESS_SECRET!: string;

  // Access-token lifetime in seconds (default 900 = 15 minutes).
  @Type(() => Number)
  @IsInt()
  @Min(60)
  @IsOptional()
  JWT_ACCESS_TTL_SECONDS = 900;

  // Refresh-token lifetime in days (opaque token, hashed + stored in Postgres).
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  JWT_REFRESH_TTL_DAYS = 30;

  // Phone-OTP provider. `mock` (dev, accepts 000000) through Sprint 4; the real
  // provider is chosen in Sprint 5 (ADR 008). App refuses to boot if this is
  // `mock` while NODE_ENV=production.
  @IsEnum(OtpProvider)
  @IsOptional()
  OTP_PROVIDER: OtpProvider = OtpProvider.Mock;

  // Comma-separated accepted audiences for social-login ID-token verification.
  // Empty in dev (social login returns 503 until set); populated from the
  // Google Cloud / Apple Developer client IDs in Sprint 2.
  @IsString()
  @IsOptional()
  GOOGLE_OAUTH_CLIENT_IDS = '';

  @IsString()
  @IsOptional()
  APPLE_CLIENT_IDS = '';

  // ABR (Australian Business Register) lookup GUID. Free registration at
  // abr.business.gov.au. Empty in dev → AbrService returns a stub (non-prod
  // only) so the ABN flow is testable without the live register.
  @IsString()
  @IsOptional()
  ABR_GUID = '';

  // Comma-separated allowed browser origins for CORS (credentialed). Empty in
  // dev → defaults to the admin dev server (http://localhost:3001).
  @IsString()
  @IsOptional()
  CORS_ORIGINS = '';

  // Stripe (test mode in dev; live keys only via Key Vault). Optional so the
  // app boots without payments configured; StripeConnectService throws a clear
  // error if a Connect call is made while STRIPE_SECRET_KEY is empty.
  @IsString()
  @IsOptional()
  STRIPE_SECRET_KEY = '';

  // Verifies Stripe webhook signatures. From `stripe listen` in dev, or the
  // dashboard endpoint secret. Empty → the webhook route rejects all events.
  @IsString()
  @IsOptional()
  STRIPE_WEBHOOK_SECRET = '';

  // Base URL Stripe Connect onboarding returns to (the API builds the account
  // link return/refresh URLs from this). Dev default points at the API host.
  @IsString()
  @IsOptional()
  STRIPE_CONNECT_RETURN_URL = 'http://localhost:3000/connect/return';
}

export function validateEnv(config: Record<string, unknown>): EnvironmentVariables {
  const validated = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });

  const errors = validateSync(validated, { skipMissingProperties: false });
  if (errors.length > 0) {
    const detail = errors
      .map((e) => `  - ${e.property}: ${Object.values(e.constraints ?? {}).join(', ')}`)
      .join('\n');
    throw new Error(`Invalid environment configuration:\n${detail}`);
  }

  return validated;
}
