import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { EmailVerificationController } from './email-verification.controller';
import { EmailVerificationService } from './email-verification.service';
import { JwtAuthGuard } from './jwt-auth.guard';
import { LockoutService } from './lockout.service';
import { MailService } from './mail/mail.service';
import { MockMailService } from './mail/mock-mail.service';
import { PasswordResetController } from './password-reset.controller';
import { PasswordResetService } from './password-reset.service';
import { AppleVerifier } from './oauth/apple.verifier';
import { GoogleVerifier } from './oauth/google.verifier';
import { OAuthController } from './oauth/oauth.controller';
import { OAuthService } from './oauth/oauth.service';
import { MockOtpService } from './otp/mock-otp.service';
import { OtpController } from './otp/otp.controller';
import { OtpService } from './otp/otp.service';
import { PasswordService } from './password.service';
import { ReauthService } from './reauth.service';
import { RecentAuthGuard } from './recent-auth.guard';
import { RolesGuard } from './roles.guard';
import { TokenService } from './token.service';

@Module({
  imports: [
    UsersModule,
    // Secrets are passed per sign/verify call (TokenService), not registered here.
    JwtModule.register({}),
  ],
  controllers: [
    AuthController,
    OtpController,
    OAuthController,
    EmailVerificationController,
    PasswordResetController,
  ],
  providers: [
    AuthService,
    PasswordService,
    TokenService,
    LockoutService,
    OAuthService,
    GoogleVerifier,
    AppleVerifier,
    EmailVerificationService,
    PasswordResetService,
    ReauthService,
    // OtpService → MockOtpService for now; Sprint 5 swaps the impl (ADR 008).
    { provide: OtpService, useClass: MockOtpService },
    // MailService → MockMailService for now; SendGrid in Sprint 5/8.
    { provide: MailService, useClass: MockMailService },
    // Guard order matters: authenticate (JWT) → authorize (roles) → step-up.
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
    { provide: APP_GUARD, useClass: RecentAuthGuard },
  ],
})
export class AuthModule {}
