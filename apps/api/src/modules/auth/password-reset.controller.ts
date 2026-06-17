import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/auth/public.decorator';
import { RateLimit } from '../../common/rate-limit/rate-limit.decorator';
import { ForgotPasswordDto, ResetPasswordDto } from './dto/account.dto';
import { PasswordResetService } from './password-reset.service';

const IDEMPOTENCY_HEADER = {
  name: 'Idempotency-Key',
  description: 'Required on mutating requests; replays the response on retry.',
  required: true,
};

@ApiTags('auth')
@Controller('auth/password')
export class PasswordResetController {
  constructor(private readonly passwordReset: PasswordResetService) {}

  @Public()
  @Post('forgot')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 5, duration: 300 })
  @ApiOperation({ summary: 'Request a password-reset email' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  async forgot(@Body() dto: ForgotPasswordDto): Promise<{ ok: true }> {
    await this.passwordReset.forgot(dto.email);
    // Always 200 — do not reveal whether the email exists.
    return { ok: true };
  }

  @Public()
  @Post('reset')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 5, duration: 300 })
  @ApiOperation({ summary: 'Reset the password with a token' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  async reset(@Body() dto: ResetPasswordDto): Promise<{ reset: true }> {
    await this.passwordReset.reset(dto.token, dto.newPassword);
    return { reset: true };
  }
}
