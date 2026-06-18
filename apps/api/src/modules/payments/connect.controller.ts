import { Controller, Get, HttpCode, HttpStatus, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { UserRole } from '@jobbees/prisma';
import { CurrentUser, type CurrentUserData } from '../../common/auth/current-user.decorator';
import { Roles } from '../../common/auth/roles.decorator';
import { RateLimit } from '../../common/rate-limit/rate-limit.decorator';
import { ConnectOnboardingDto, ConnectStatusDto } from './dto/connect.dto';
import { StripeConnectService } from './stripe-connect.service';

/**
 * Tasker payout onboarding (Stripe Connect Express). TASKER-only: clients don't
 * receive payouts. The role switch flips CLIENT→TASKER first, then this runs.
 */
@ApiTags('payments')
@ApiBearerAuth()
@Roles(UserRole.TASKER)
@Controller('me/connect')
export class ConnectController {
  constructor(private readonly connect: StripeConnectService) {}

  @Post('onboard')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 10, duration: 60 })
  @ApiOperation({ summary: 'Start/continue Stripe Connect onboarding (tasker)' })
  @ApiHeader({ name: 'Idempotency-Key', required: true })
  onboard(
    @CurrentUser() user: CurrentUserData,
    @Req() req: Request,
  ): Promise<ConnectOnboardingDto> {
    return this.connect.startOnboarding(user.id, {
      ipAddress: req.ip ?? null,
      userAgent: req.header('user-agent') ?? null,
    });
  }

  @Get('status')
  @ApiOperation({ summary: 'Current payout-onboarding status (tasker)' })
  status(@CurrentUser() user: CurrentUserData): Promise<ConnectStatusDto> {
    return this.connect.syncStatus(user.id);
  }
}
