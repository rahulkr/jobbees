import {
  BadRequestException,
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Req,
  Res,
} from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Request, Response } from 'express';
import { CurrentUser, type CurrentUserData } from '../../common/auth/current-user.decorator';
import { Public } from '../../common/auth/public.decorator';
import { RateLimit } from '../../common/rate-limit/rate-limit.decorator';
import { AuthService } from './auth.service';
import {
  LoginDto,
  ReauthDto,
  RefreshDto,
  SignupDto,
  TokenPairDto,
  UserProfileDto,
} from './dto/auth.dto';
import { readCookie, REFRESH_COOKIE, SessionCookieService } from './session-cookie.service';
import { type IssueContext } from './token.service';

/** Mobile gets the token pair in the body; web gets cookies + a csrfToken. */
type SessionResponse = TokenPairDto | { csrfToken: string };

function contextFrom(req: Request): IssueContext {
  return { ipAddress: req.ip ?? null, userAgent: req.header('user-agent') ?? null };
}

const IDEMPOTENCY_HEADER = {
  name: 'Idempotency-Key',
  description: 'Required on mutating requests; replays the response on retry.',
  required: true,
};

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly session: SessionCookieService,
  ) {}

  @Public()
  @Post('signup')
  @RateLimit({ points: 5, duration: 60 })
  @ApiOperation({ summary: 'Register with email + password' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  async signup(
    @Body() dto: SignupDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ): Promise<SessionResponse> {
    const pair = await this.auth.signup(dto, contextFrom(req));
    return this.session.deliver(req, res, pair);
  }

  @Public()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 5, duration: 60 })
  @ApiOperation({ summary: 'Log in with email + password' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  async login(
    @Body() dto: LoginDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ): Promise<SessionResponse> {
    const pair = await this.auth.login(dto, contextFrom(req));
    return this.session.deliver(req, res, pair);
  }

  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 10, duration: 60 })
  @ApiOperation({ summary: 'Exchange a refresh token for a new token pair' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  async refresh(
    @Body() dto: RefreshDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ): Promise<SessionResponse> {
    const token = this.session.isWeb(req) ? readCookie(req, REFRESH_COOKIE) : dto.refreshToken;
    if (!token) {
      throw new BadRequestException('Missing refresh token');
    }
    const pair = await this.auth.refresh(token, contextFrom(req));
    return this.session.deliver(req, res, pair);
  }

  @Public()
  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  @RateLimit({ points: 10, duration: 60 })
  @ApiOperation({ summary: 'Revoke a refresh token' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  async logout(
    @Body() dto: RefreshDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ): Promise<void> {
    const token = this.session.isWeb(req) ? readCookie(req, REFRESH_COOKIE) : dto.refreshToken;
    if (token) {
      await this.auth.logout(token);
    }
    this.session.clear(res);
  }

  @Post('logout-all')
  @HttpCode(HttpStatus.NO_CONTENT)
  @RateLimit({ points: 10, duration: 60 })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Revoke every session for the current user' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  async logoutAll(
    @CurrentUser() user: CurrentUserData,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ): Promise<void> {
    await this.auth.logoutAll(user.id, contextFrom(req));
    this.session.clear(res);
  }

  @Post('reauth')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 5, duration: 60 })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Step-up: re-verify password for sensitive actions' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  reauth(
    @CurrentUser() user: CurrentUserData,
    @Body() dto: ReauthDto,
    @Req() req: Request,
  ): Promise<{ validForSeconds: number }> {
    return this.auth.reauth(user.id, dto.password, contextFrom(req));
  }

  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Current authenticated user' })
  me(@CurrentUser() user: CurrentUserData): Promise<UserProfileDto> {
    return this.auth.me(user.id);
  }
}
