import { Body, Controller, Get, HttpCode, HttpStatus, Patch, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { UserRole } from '@jobbees/prisma';
import { CurrentUser, type CurrentUserData } from '../../common/auth/current-user.decorator';
import { Roles } from '../../common/auth/roles.decorator';
import { RateLimit } from '../../common/rate-limit/rate-limit.decorator';
import { TaskerProfileDto, UpdateTaskerProfileDto } from './dto/profile.dto';
import { RoleResultDto } from './dto/role-result.dto';
import { UsersService } from './users.service';

/**
 * Self-service account endpoints. CLIENT and TASKER are both allowed: the
 * upgrade flips CLIENT→TASKER and switch-to-client flips it back — each is an
 * idempotent no-op when already in the target role (also covers retries on a
 * not-yet-refreshed access token). Becoming a tasker keeps verification, so the
 * two are a reversible pair.
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
    summary: 'Upgrade the current client account to a tasker (reversible via switch-to-client)',
  })
  @ApiHeader({ name: 'Idempotency-Key', required: true })
  async becomeTasker(
    @CurrentUser() user: CurrentUserData,
    @Req() req: Request,
  ): Promise<RoleResultDto> {
    const updated = await this.users.becomeTasker(user.id, {
      ipAddress: req.ip ?? null,
      userAgent: req.header('user-agent') ?? null,
    });
    return { role: updated.role };
  }

  @Post('switch-to-client')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 10, duration: 60 })
  @ApiOperation({
    summary: 'Switch the current tasker account back to a client (reversible; keeps verification)',
  })
  @ApiHeader({ name: 'Idempotency-Key', required: true })
  async switchToClient(
    @CurrentUser() user: CurrentUserData,
    @Req() req: Request,
  ): Promise<RoleResultDto> {
    const updated = await this.users.switchToClient(user.id, {
      ipAddress: req.ip ?? null,
      userAgent: req.header('user-agent') ?? null,
    });
    return { role: updated.role };
  }

  @Get('profile')
  @Roles(UserRole.TASKER)
  @ApiOperation({ summary: 'Get the current tasker profile' })
  getProfile(@CurrentUser() user: CurrentUserData): Promise<TaskerProfileDto> {
    return this.users.getTaskerProfile(user.id);
  }

  @Patch('profile')
  @Roles(UserRole.TASKER)
  @RateLimit({ points: 20, duration: 60 })
  @ApiOperation({ summary: 'Update the current tasker profile' })
  @ApiHeader({ name: 'Idempotency-Key', required: true })
  updateProfile(
    @CurrentUser() user: CurrentUserData,
    @Body() dto: UpdateTaskerProfileDto,
  ): Promise<TaskerProfileDto> {
    return this.users.updateTaskerProfile(user.id, dto);
  }
}
