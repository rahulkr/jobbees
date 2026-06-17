import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserRole } from '@jobbees/prisma';
import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

const SIGNUP_ROLES = [UserRole.CLIENT, UserRole.TASKER] as const;

export class OAuthLoginDto {
  @ApiProperty({ description: 'Provider ID token obtained by the client SDK.' })
  @IsString()
  @MinLength(1)
  idToken!: string;

  @ApiPropertyOptional({
    enum: SIGNUP_ROLES,
    default: UserRole.CLIENT,
    description: 'Role to assign on first-time signup.',
  })
  @IsOptional()
  @IsIn(SIGNUP_ROLES)
  role?: (typeof SIGNUP_ROLES)[number];

  @ApiPropertyOptional({
    description: 'Client-supplied name (Apple sends it only on first auth).',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  firstName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(100)
  lastName?: string;
}
