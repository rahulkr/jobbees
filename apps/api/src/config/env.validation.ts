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
