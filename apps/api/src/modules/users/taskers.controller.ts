import { Controller, Get, Param } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { PublicTaskerProfileDto } from './dto/public-tasker-profile.dto';
import { UsersService } from './users.service';

/**
 * Public tasker profiles, visible to any signed-in user (clients browsing
 * taskers). Authenticated but not role-gated; the projection is narrow so no
 * PII leaks (security-review E4).
 */
@ApiTags('taskers')
@ApiBearerAuth()
@Controller('taskers')
export class TaskersController {
  constructor(private readonly users: UsersService) {}

  @Get(':id')
  @ApiOperation({ summary: 'Public tasker profile (signed-in users)' })
  getProfile(@Param('id') id: string): Promise<PublicTaskerProfileDto> {
    return this.users.getPublicTaskerProfile(id);
  }
}
