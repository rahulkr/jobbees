import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuditLogService } from '../../../common/audit/audit-log.service';
import { NodeEnv } from '../../../config/env.validation';
import { OtpService } from './otp.service';

const MOCK_CODE = '000000';

/** Mask all but the last 3 digits — never log/store a full phone number (PII). */
function maskPhone(phone: string): string {
  return phone.length <= 3 ? '***' : `***${phone.slice(-3)}`;
}

/**
 * Dev-only OTP provider (ADR 008). Accepts the hardcoded code `000000` for any
 * phone. Three safety guards keep it out of production:
 *   1. Startup assertion — refuses to boot when NODE_ENV=production (here).
 *   2. AuditLog on every send + verify (here).
 *   3. Semgrep rule `jobbees-mock-otp-in-prod-env` blocks `OTP_PROVIDER=mock`
 *      in committed env files (ops/security/semgrep-rules.yml).
 */
@Injectable()
export class MockOtpService extends OtpService implements OnModuleInit {
  private readonly logger = new Logger(MockOtpService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly audit: AuditLogService,
  ) {
    super();
  }

  onModuleInit(): void {
    if (this.config.get<string>('NODE_ENV') === NodeEnv.Production) {
      throw new Error(
        'FATAL: MockOtpService must never run with NODE_ENV=production. ' +
          'Set OTP_PROVIDER to a real provider.',
      );
    }
    this.logger.warn('MockOtpService active — any phone accepts code 000000 (dev only)');
  }

  async send(phone: string): Promise<void> {
    this.logger.log(`[MOCK OTP] ${maskPhone(phone)} — code ${MOCK_CODE} (no SMS sent)`);
    await this.audit.record({
      action: 'otp.mock_send',
      resourceType: 'Phone',
      resourceId: maskPhone(phone),
    });
  }

  async verify(phone: string, code: string): Promise<boolean> {
    const ok = code === MOCK_CODE;
    await this.audit.record({
      action: 'otp.mock_verify',
      resourceType: 'Phone',
      resourceId: maskPhone(phone),
      diff: { ok },
    });
    return ok;
  }
}
