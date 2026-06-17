import { ConfigService } from '@nestjs/config';
import { AuditLogService } from '../../../common/audit/audit-log.service';
import { MockOtpService } from './mock-otp.service';

function build(nodeEnv = 'development') {
  const config = { get: jest.fn().mockReturnValue(nodeEnv) };
  const audit = { record: jest.fn().mockResolvedValue(undefined) };
  const service = new MockOtpService(
    config as unknown as ConfigService,
    audit as unknown as AuditLogService,
  );
  return { service, audit };
}

describe('MockOtpService', () => {
  it('refuses to boot in production (guard #1)', () => {
    const { service } = build('production');
    expect(() => service.onModuleInit()).toThrow(/NODE_ENV=production/);
  });

  it('boots in development', () => {
    const { service } = build('development');
    expect(() => service.onModuleInit()).not.toThrow();
  });

  it('verifies the magic code and audits (guard #2)', async () => {
    const { service, audit } = build();
    await expect(service.verify('+61400000000', '000000')).resolves.toBe(true);
    expect(audit.record).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'otp.mock_verify' }),
    );
  });

  it('rejects a wrong code', async () => {
    const { service } = build();
    await expect(service.verify('+61400000000', '123456')).resolves.toBe(false);
  });

  it('audits sends and never logs the full phone number', async () => {
    const { service, audit } = build();
    await service.send('+61400000123');
    const call = audit.record.mock.calls[0][0];
    expect(call.action).toBe('otp.mock_send');
    expect(call.resourceId).toBe('***123');
    expect(call.resourceId).not.toContain('61400000');
  });
});
