import { Injectable, Logger } from '@nestjs/common';
import { AuditLogService } from '../../../common/audit/audit-log.service';
import { MailService } from './mail.service';

/** Mask the local part of an email — never log/store it in full (PII). */
function maskEmail(email: string): string {
  const [local, domain] = email.split('@');
  if (!domain) return '***';
  return `${local.slice(0, 1)}***@${domain}`;
}

/**
 * Dev mail provider: logs the link instead of sending, and audits each send.
 * No real email until SendGrid lands (Sprint 5/8).
 */
@Injectable()
export class MockMailService extends MailService {
  private readonly logger = new Logger(MockMailService.name);

  constructor(private readonly audit: AuditLogService) {
    super();
  }

  async sendEmailVerification(email: string, token: string): Promise<void> {
    this.logger.log(
      `[MOCK MAIL] verify ${maskEmail(email)} — token ${token.slice(0, 8)}… (no email sent)`,
    );
    await this.audit.record({
      action: 'mail.mock_email_verification',
      resourceType: 'Email',
      resourceId: maskEmail(email),
    });
  }

  async sendPasswordReset(email: string, token: string): Promise<void> {
    this.logger.log(
      `[MOCK MAIL] reset ${maskEmail(email)} — token ${token.slice(0, 8)}… (no email sent)`,
    );
    await this.audit.record({
      action: 'mail.mock_password_reset',
      resourceType: 'Email',
      resourceId: maskEmail(email),
    });
  }
}
