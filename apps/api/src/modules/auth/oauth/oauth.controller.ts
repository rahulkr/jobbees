import { Body, Controller, HttpCode, HttpStatus, Param, Post, Req } from '@nestjs/common';
import { ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { Public } from '../../../common/auth/public.decorator';
import { RateLimit } from '../../../common/rate-limit/rate-limit.decorator';
import { TokenPairDto } from '../dto/auth.dto';
import { OAuthLoginDto } from '../dto/oauth.dto';
import { type IssueContext } from '../token.service';
import { OAuthService } from './oauth.service';

function contextFrom(req: Request): IssueContext {
  return { ipAddress: req.ip ?? null, userAgent: req.header('user-agent') ?? null };
}

@ApiTags('auth')
@Controller('auth/oauth')
export class OAuthController {
  constructor(private readonly oauth: OAuthService) {}

  @Public()
  @Post(':provider')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 10, duration: 60 })
  @ApiOperation({ summary: 'Sign in with a provider (provider = google | apple)' })
  @ApiHeader({
    name: 'Idempotency-Key',
    required: true,
    description: 'Required on mutating requests; replays the response on retry.',
  })
  login(
    @Param('provider') provider: string,
    @Body() dto: OAuthLoginDto,
    @Req() req: Request,
  ): Promise<TokenPairDto> {
    return this.oauth.login(provider, dto, contextFrom(req));
  }
}
