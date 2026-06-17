import { Module } from '@nestjs/common';
import { AdminUsersController } from './admin-users.controller';
import { AdminUsersService } from './admin-users.service';

/**
 * Admin operations. Just user suspension/reinstatement at Sprint 1 — the full
 * admin console is Sprint 9. PrismaService + AuditLogService are global.
 */
@Module({
  controllers: [AdminUsersController],
  providers: [AdminUsersService],
})
export class AdminModule {}
