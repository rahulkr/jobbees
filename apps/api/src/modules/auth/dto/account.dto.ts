import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MaxLength, MinLength } from 'class-validator';

export class VerifyEmailDto {
  @ApiProperty({ description: 'The token from the verification email.' })
  @IsString()
  @MinLength(1)
  token!: string;
}

export class ForgotPasswordDto {
  @ApiProperty({ example: 'jordan@example.com' })
  @IsEmail()
  email!: string;
}

export class ResetPasswordDto {
  @ApiProperty({ description: 'The token from the password-reset email.' })
  @IsString()
  @MinLength(1)
  token!: string;

  @ApiProperty({ minLength: 10, maxLength: 200 })
  @IsString()
  @MinLength(10)
  @MaxLength(200)
  newPassword!: string;
}
