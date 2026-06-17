import { Body, Controller, Get, HttpCode, HttpStatus, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags, ApiHeader } from '@nestjs/swagger';
import type { Request } from 'express';
import { CurrentUser, type CurrentUserData } from '../../common/auth/current-user.decorator';
import { Public } from '../../common/auth/public.decorator';
import { RateLimit } from '../../common/rate-limit/rate-limit.decorator';
import { AuthService } from './auth.service';
import { LoginDto, RefreshDto, SignupDto, TokenPairDto, UserProfileDto } from './dto/auth.dto';
import { type IssueContext } from './token.service';

function contextFrom(req: Request): IssueContext {
  return { ipAddress: req.ip ?? null, userAgent: req.header('user-agent') ?? null };
}

// All mutating routes require an Idempotency-Key (global interceptor).
const IDEMPOTENCY_HEADER = {
  name: 'Idempotency-Key',
  description: 'Required on mutating requests; replays the response on retry.',
  required: true,
};

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Public()
  @Post('signup')
  @RateLimit({ points: 5, duration: 60 })
  @ApiOperation({ summary: 'Register with email + password' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  signup(@Body() dto: SignupDto, @Req() req: Request): Promise<TokenPairDto> {
    return this.auth.signup(dto, contextFrom(req));
  }

  @Public()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 5, duration: 60 })
  @ApiOperation({ summary: 'Log in with email + password' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  login(@Body() dto: LoginDto, @Req() req: Request): Promise<TokenPairDto> {
    return this.auth.login(dto, contextFrom(req));
  }

  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 10, duration: 60 })
  @ApiOperation({ summary: 'Exchange a refresh token for a new token pair' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  refresh(@Body() dto: RefreshDto, @Req() req: Request): Promise<TokenPairDto> {
    return this.auth.refresh(dto.refreshToken, contextFrom(req));
  }

  @Public()
  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  @RateLimit({ points: 10, duration: 60 })
  @ApiOperation({ summary: 'Revoke a refresh token' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  async logout(@Body() dto: RefreshDto): Promise<void> {
    await this.auth.logout(dto.refreshToken);
  }

  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Current authenticated user' })
  me(@CurrentUser() user: CurrentUserData): Promise<UserProfileDto> {
    return this.auth.me(user.id);
  }
}
