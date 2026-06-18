import { BadRequestException } from '@nestjs/common';
import type { AuditLogService } from '../../common/audit/audit-log.service';
import type { PrismaService } from '../../prisma/prisma.service';
import { AbnService } from './abn.service';
import type { AbrResult, AbrService } from './abr.service';

const VALID_ABN = '51824753556'; // ATO documentation example

function build(lookup: AbrResult | null) {
  const prisma = {
    user: {
      update: jest.fn().mockImplementation(({ data }) =>
        Promise.resolve({
          abn: data.abn,
          abrBusinessName: data.abrBusinessName,
          abnVerifiedAt: data.abnVerifiedAt,
        }),
      ),
      findFirst: jest.fn(),
    },
  };
  const abr = { lookup: jest.fn().mockResolvedValue(lookup) };
  const audit = { record: jest.fn().mockResolvedValue(undefined) };
  const service = new AbnService(
    prisma as unknown as PrismaService,
    abr as unknown as AbrService,
    audit as unknown as AuditLogService,
  );
  return { service, prisma, abr, audit };
}

describe('AbnService', () => {
  it('rejects an invalid ABN without touching the DB or ABR', async () => {
    const { service, prisma, abr, audit } = build(null);

    await expect(service.submitAbn('user_1', '11111111111')).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(abr.lookup).not.toHaveBeenCalled();
    expect(prisma.user.update).not.toHaveBeenCalled();
    expect(audit.record).not.toHaveBeenCalled();
  });

  it('stores a verified ABN when the ABR confirms it is active', async () => {
    const { service, prisma, audit } = build({
      abn: VALID_ABN,
      businessName: 'Test Business Pty Ltd',
      isActive: true,
      gstRegistered: true,
    });

    const result = await service.submitAbn('user_1', '51 824 753 556');

    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'user_1' },
        data: expect.objectContaining({
          abn: VALID_ABN,
          abrBusinessName: 'Test Business Pty Ltd',
          abnVerifiedAt: expect.any(Date),
          noAbnReason: null,
        }),
      }),
    );
    expect(result.businessName).toBe('Test Business Pty Ltd');
    expect(result.verifiedAt).toBeInstanceOf(Date);
    expect(audit.record).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'user.abn_submitted',
        diff: { abnLast3: '556', verified: true },
      }),
    );
  });

  it('stores the ABN as pending when the ABR cannot confirm it', async () => {
    const { service, prisma } = build(null); // no ABR result

    const result = await service.submitAbn('user_1', VALID_ABN);

    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ abn: VALID_ABN, abnVerifiedAt: null }),
      }),
    );
    expect(result.verifiedAt).toBeNull();
  });
});
