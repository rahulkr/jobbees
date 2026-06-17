import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';
import { LockoutService } from './lockout.service';
import { MockOtpService } from './otp/mock-otp.service';
import { OtpController } from './otp/otp.controller';
import { OtpService } from './otp/otp.service';
import { PasswordService } from './password.service';
import { RolesGuard } from './roles.guard';
import { TokenService } from './token.service';

@Module({
  imports: [
    UsersModule,
    // Secrets are passed per sign/verify call (TokenService), not registered here.
    JwtModule.register({}),
  ],
  controllers: [AuthController, OtpController],
  providers: [
    AuthService,
    PasswordService,
    TokenService,
    LockoutService,
    // OtpService → MockOtpService for now; Sprint 5 swaps the impl (ADR 008).
    { provide: OtpService, useClass: MockOtpService },
    // Guard order matters: authenticate (JWT) before authorizing (roles).
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
})
export class AuthModule {}
