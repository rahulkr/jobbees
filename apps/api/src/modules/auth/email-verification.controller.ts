import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UnauthorizedException,
} from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser, type CurrentUserData } from '../../common/auth/current-user.decorator';
import { Public } from '../../common/auth/public.decorator';
import { RateLimit } from '../../common/rate-limit/rate-limit.decorator';
import { UsersService } from '../users/users.service';
import { VerifyEmailDto } from './dto/account.dto';
import { EmailVerificationService } from './email-verification.service';

const IDEMPOTENCY_HEADER = {
  name: 'Idempotency-Key',
  description: 'Required on mutating requests; replays the response on retry.',
  required: true,
};

@ApiTags('auth')
@Controller('auth/email')
export class EmailVerificationController {
  constructor(
    private readonly emailVerification: EmailVerificationService,
    private readonly users: UsersService,
  ) {}

  @Public()
  @Post('verify')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 10, duration: 60 })
  @ApiOperation({ summary: 'Verify an email address' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  async verify(@Body() dto: VerifyEmailDto): Promise<{ verified: true }> {
    await this.emailVerification.verify(dto.token);
    return { verified: true };
  }

  @Post('resend')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 3, duration: 60 })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Resend the verification email to the current user' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  async resend(@CurrentUser() user: CurrentUserData): Promise<{ sent: true }> {
    const full = await this.users.findById(user.id);
    if (!full) {
      throw new UnauthorizedException('User no longer exists');
    }
    await this.emailVerification.resend(full.id, full.email);
    return { sent: true };
  }
}
