import { Global, Module } from '@nestjs/common';
import { AuditLogService } from './audit-log.service';

/** Global so any module can record audit entries without re-importing. */
@Global()
@Module({
  providers: [AuditLogService],
  exports: [AuditLogService],
})
export class AuditModule {}
