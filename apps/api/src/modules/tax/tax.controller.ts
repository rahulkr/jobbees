import { Body, Controller, Get, HttpCode, HttpStatus, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { UserRole } from '@jobbees/prisma';
import { CurrentUser, type CurrentUserData } from '../../common/auth/current-user.decorator';
import { RateLimit } from '../../common/rate-limit/rate-limit.decorator';
import { Roles } from '../../common/auth/roles.decorator';
import { AbnService } from './abn.service';
import { AbnStatusDto, SubmitAbnDto } from './dto/abn.dto';

/**
 * Tasker ABN endpoints. TASKER-only: clients don't carry an ABN. The
 * client→tasker upgrade flips the role first, then collects the ABN here.
 */
@ApiTags('tax')
@ApiBearerAuth()
@Roles(UserRole.TASKER)
@Controller('me/abn')
export class TaxController {
  constructor(private readonly abn: AbnService) {}

  @Post()
  @HttpCode(HttpStatus.OK)
  @RateLimit({ points: 10, duration: 60 })
  @ApiOperation({ summary: 'Submit + verify an ABN against the ABR (tasker only)' })
  @ApiHeader({ name: 'Idempotency-Key', required: true })
  submit(
    @CurrentUser() user: CurrentUserData,
    @Body() dto: SubmitAbnDto,
    @Req() req: Request,
  ): Promise<AbnStatusDto> {
    return this.abn.submitAbn(user.id, dto.abn, {
      ipAddress: req.ip ?? null,
      userAgent: req.header('user-agent') ?? null,
    });
  }

  @Get()
  @ApiOperation({ summary: 'Current ABN verification status (tasker only)' })
  status(@CurrentUser() user: CurrentUserData): Promise<AbnStatusDto> {
    return this.abn.getStatus(user.id);
  }
}
