import { Body, Controller, HttpCode, HttpStatus, Param, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@jobbees/prisma';
import type { Request } from 'express';
import { CurrentUser, type CurrentUserData } from '../../common/auth/current-user.decorator';
import { Roles } from '../../common/auth/roles.decorator';
import { RateLimit } from '../../common/rate-limit/rate-limit.decorator';
import { AdminUsersService } from './admin-users.service';
import { SuspendUserDto } from './dto/suspend-user.dto';

function contextFrom(req: Request) {
  return { ipAddress: req.ip ?? null, userAgent: req.header('user-agent') ?? null };
}

const IDEMPOTENCY_HEADER = {
  name: 'Idempotency-Key',
  description: 'Required on mutating requests; replays the response on retry.',
  required: true,
};

@ApiTags('admin')
@ApiBearerAuth()
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@Controller('admin/users')
export class AdminUsersController {
  constructor(private readonly adminUsers: AdminUsersService) {}

  @Post(':id/suspend')
  @HttpCode(HttpStatus.NO_CONTENT)
  @RateLimit({ points: 30, duration: 60 })
  @ApiOperation({ summary: 'Suspend a user (revokes their sessions)' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  async suspend(
    @CurrentUser() actor: CurrentUserData,
    @Param('id') id: string,
    @Body() dto: SuspendUserDto,
    @Req() req: Request,
  ): Promise<void> {
    await this.adminUsers.suspend(actor.id, id, dto.reason, contextFrom(req));
  }

  @Post(':id/reinstate')
  @HttpCode(HttpStatus.NO_CONTENT)
  @RateLimit({ points: 30, duration: 60 })
  @ApiOperation({ summary: 'Reinstate a suspended user' })
  @ApiHeader(IDEMPOTENCY_HEADER)
  async reinstate(
    @CurrentUser() actor: CurrentUserData,
    @Param('id') id: string,
    @Req() req: Request,
  ): Promise<void> {
    await this.adminUsers.reinstate(actor.id, id, contextFrom(req));
  }
}
