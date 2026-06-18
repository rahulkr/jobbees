import { Controller, HttpCode, HttpStatus, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { UserRole } from '@jobbees/prisma';
import { CurrentUser, type CurrentUserData } from '../../common/auth/current-user.decorator';
import { Roles } from '../../common/auth/roles.decorator';
import { RateLimit } from '../../common/rate-limit/rate-limit.decorator';
import { BecomeTaskerResultDto } from './dto/become-tasker.dto';
import { UsersService } from './users.service';

/**
 * Self-service account endpoints. CLIENT and TASKER are both allowed: the
 * upgrade flips CLIENT→TASKER, and a TASKER hitting it again is an idempotent
 * no-op (also covers retries on a not-yet-refreshed CLIENT access token).
 */
@ApiTags('users')
@ApiBearerAuth()
@Roles(UserRole.CLIENT, UserRole.TASKER)
@Controller('me')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Post('become-tasker')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 10, duration: 60 })
  @ApiOperation({
    summary: 'Upgrade the current client account to a tasker (one-way)',
  })
  @ApiHeader({ name: 'Idempotency-Key', required: true })
  async becomeTasker(
    @CurrentUser() user: CurrentUserData,
    @Req() req: Request,
  ): Promise<BecomeTaskerResultDto> {
    const updated = await this.users.becomeTasker(user.id, {
      ipAddress: req.ip ?? null,
      userAgent: req.header('user-agent') ?? null,
    });
    return { role: updated.role };
  }
}
