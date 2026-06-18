import { Module } from '@nestjs/common';
import { AbnService } from './abn.service';
import { AbrService } from './abr.service';
import { TaxController } from './tax.controller';

/**
 * Tax module. Sprint 2 lands ABN + ABR lookup (tasker verification); GST,
 * RCTI, invoices, and ATO export join here in Sprint 6.
 */
@Module({
  controllers: [TaxController],
  providers: [AbnService, AbrService],
  exports: [AbnService, AbrService],
})
export class TaxModule {}
