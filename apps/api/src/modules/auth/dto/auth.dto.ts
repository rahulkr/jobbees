import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserRole } from '@jobbees/prisma';
import { IsEmail, IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

/** Self-serve signup may only create CLIENT or TASKER — never an admin role. */
const SIGNUP_ROLES = [UserRole.CLIENT, UserRole.TASKER] as const;

export class SignupDto {
  @ApiProperty({ example: 'jordan@example.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'a-strong-passphrase', minLength: 10, maxLength: 200 })
  @IsString()
  @MinLength(10)
  @MaxLength(200)
  password!: string;

  @ApiProperty({ example: 'Jordan' })
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  firstName!: string;

  @ApiProperty({ example: 'Lee' })
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  lastName!: string;

  @ApiPropertyOptional({ enum: SIGNUP_ROLES, default: UserRole.CLIENT })
  @IsOptional()
  @IsIn(SIGNUP_ROLES)
  role?: (typeof SIGNUP_ROLES)[number];
}

export class LoginDto {
  @ApiProperty({ example: 'jordan@example.com' })
  @IsEmail()
  email!: string;

  @ApiProperty()
  @IsString()
  @MinLength(1)
  password!: string;
}

export class RefreshDto {
  @ApiProperty({ description: 'The opaque refresh token issued at login.' })
  @IsString()
  @MinLength(1)
  refreshToken!: string;
}

export class ReauthDto {
  @ApiProperty({ description: 'Current password, to unlock sensitive actions.' })
  @IsString()
  @MinLength(1)
  password!: string;
}

export class TokenPairDto {
  @ApiProperty()
  accessToken!: string;

  @ApiProperty()
  refreshToken!: string;
}

export class UserProfileDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  email!: string;

  @ApiProperty()
  firstName!: string;

  @ApiProperty()
  lastName!: string;

  @ApiProperty({ enum: UserRole })
  role!: UserRole;

  @ApiProperty()
  emailVerified!: boolean;

  @ApiProperty()
  phoneVerified!: boolean;

  @ApiProperty()
  createdAt!: Date;
}
