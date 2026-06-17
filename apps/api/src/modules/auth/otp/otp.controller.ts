import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@jobbees/prisma';
import { CurrentUser, type CurrentUserData } from '../../../common/auth/current-user.decorator';
import { RateLimit } from '../../../common/rate-limit/rate-limit.decorator';
import { Roles } from '../../../common/auth/roles.decorator';
import { AuthService } from '../auth.service';
import { OtpSendDto, OtpVerifyDto } from '../dto/otp.dto';

const IDEMPOTENCY_HEADER = {
  name: 'Idempotency-Key',
  description: 'Required on mutating requests; replays the response on retry.',
  required: true,
};

/**
 * Phone-OTP verification. Authenticated + TASKER-only — clients skip phone
 * verification (sprint row 234). RolesGuard enforces the @Roles tag.
 */
@ApiTags('auth')
@ApiBearerAuth()
@Roles(UserRole.TASKER)
@Controller('auth/otp')
export class OtpController {
  constructor(private readonly auth: AuthService) {}

  @Post('send')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 5, duration: 60 })
  @ApiOperation({ summary: 'Send a phone OTP (tasker only)' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  send(@CurrentUser() user: CurrentUserData, @Body() dto: OtpSendDto): Promise<{ sent: true }> {
    return this.auth.requestPhoneOtp(user.id, dto.phone);
  }

  @Post('verify')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 5, duration: 60 })
  @ApiOperation({ summary: 'Verify a phone OTP (tasker only)' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  verify(
    @CurrentUser() user: CurrentUserData,
    @Body() dto: OtpVerifyDto,
  ): Promise<{ phoneVerified: true }> {
    return this.auth.verifyPhoneOtp(user.id, dto.phone, dto.code);
  }
}
