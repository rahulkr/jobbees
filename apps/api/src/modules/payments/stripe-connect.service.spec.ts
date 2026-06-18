import { ForbiddenException, ServiceUnavailableException } from '@nestjs/common';
import { ConnectStatus, UserRole } from '@jobbees/prisma';
import type { ConfigService } from '@nestjs/config';
import type { AuditLogService } from '../../common/audit/audit-log.service';
import type { PrismaService } from '../../prisma/prisma.service';
import { StripeConnectService } from './stripe-connect.service';

function build(config: Record<string, string> = {}) {
  // Map (not a plain object) so the get() lookup doesn't trip
  // security/detect-object-injection on a dynamic key.
  const cfg = new Map<string, string>([
    ['STRIPE_WEBHOOK_SECRET', 'whsec_test'],
    ['STRIPE_CONNECT_RETURN_URL', 'https://app.example.com/connect/return'],
    ...Object.entries(config),
  ]);
  const stripe = {
    accounts: {
      create: jest.fn().mockResolvedValue({ id: 'acct_new' }),
      retrieve: jest.fn(),
    },
    accountLinks: {
      create: jest.fn().mockResolvedValue({ url: 'https://connect.stripe.com/setup/e/x' }),
    },
    webhooks: { constructEvent: jest.fn() },
  };
  const prisma = {
    user: {
      findFirst: jest.fn(),
      update: jest.fn().mockResolvedValue({}),
    },
  };
  const audit = { record: jest.fn().mockResolvedValue(undefined) };
  const service = new StripeConnectService(
    stripe as never,
    { get: (k: string, d?: string) => cfg.get(k) ?? d } as unknown as ConfigService,
    prisma as unknown as PrismaService,
    audit as unknown as AuditLogService,
  );
  return { service, stripe, prisma, audit };
}

const tasker = {
  id: 'u1',
  role: UserRole.TASKER,
  email: 'tasker@example.com',
  countryCode: 'AU',
  stripeAccountId: null as string | null,
  connectStatus: ConnectStatus.NOT_STARTED,
};

describe('StripeConnectService', () => {
  it('creates an Express account on first onboarding and audits it', async () => {
    const { service, stripe, prisma, audit } = build();
    prisma.user.findFirst.mockResolvedValue({ ...tasker });

    const result = await service.startOnboarding('u1', {});

    expect(stripe.accounts.create).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'express', country: 'AU' }),
      expect.objectContaining({ idempotencyKey: 'connect-create-u1' }),
    );
    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: {
          stripeAccountId: 'acct_new',
          connectStatus: ConnectStatus.PENDING,
        },
      }),
    );
    expect(audit.record).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'connect.account_created' }),
    );
    expect(result.url).toContain('connect.stripe.com');
  });

  it('reuses an existing account (no second create)', async () => {
    const { service, stripe, prisma } = build();
    prisma.user.findFirst.mockResolvedValue({
      ...tasker,
      stripeAccountId: 'acct_existing',
    });

    await service.startOnboarding('u1', {});

    expect(stripe.accounts.create).not.toHaveBeenCalled();
    expect(stripe.accountLinks.create).toHaveBeenCalledWith(
      expect.objectContaining({ account: 'acct_existing' }),
    );
  });

  it('refuses a non-tasker', async () => {
    const { service, stripe, prisma } = build();
    prisma.user.findFirst.mockResolvedValue({
      ...tasker,
      role: UserRole.CLIENT,
    });

    await expect(service.startOnboarding('u1', {})).rejects.toBeInstanceOf(ForbiddenException);
    expect(stripe.accounts.create).not.toHaveBeenCalled();
  });

  it('syncStatus returns NOT_STARTED without hitting Stripe when no account', async () => {
    const { service, stripe, prisma } = build();
    prisma.user.findFirst.mockResolvedValue({ ...tasker });

    const result = await service.syncStatus('u1');

    expect(result.status).toBe(ConnectStatus.NOT_STARTED);
    expect(stripe.accounts.retrieve).not.toHaveBeenCalled();
  });

  it('marks COMPLETE when payouts are enabled and persists the change', async () => {
    const { service, stripe, prisma, audit } = build();
    prisma.user.findFirst.mockResolvedValue({
      ...tasker,
      stripeAccountId: 'acct_1',
      connectStatus: ConnectStatus.PENDING,
    });
    stripe.accounts.retrieve.mockResolvedValue({
      id: 'acct_1',
      payouts_enabled: true,
      details_submitted: true,
      requirements: {},
    });

    const result = await service.syncStatus('u1');

    expect(result.status).toBe(ConnectStatus.COMPLETE);
    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { connectStatus: ConnectStatus.COMPLETE },
      }),
    );
    expect(audit.record).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'connect.status_changed' }),
    );
  });

  it('handleEvent maps a rejected account to RESTRICTED', async () => {
    const { service, prisma } = build();
    prisma.user.findFirst.mockResolvedValue({
      ...tasker,
      stripeAccountId: 'acct_1',
      connectStatus: ConnectStatus.PENDING,
    });

    await service.handleEvent({
      type: 'account.updated',
      data: {
        object: {
          id: 'acct_1',
          payouts_enabled: false,
          requirements: { disabled_reason: 'rejected.fraud' },
        },
      },
    } as never);

    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { connectStatus: ConnectStatus.RESTRICTED },
      }),
    );
  });

  it('rejects webhook verification when no secret is configured', () => {
    const { service, stripe } = build({ STRIPE_WEBHOOK_SECRET: '' });

    expect(() => service.constructEvent(Buffer.from('{}'), 'sig')).toThrow(
      ServiceUnavailableException,
    );
    expect(stripe.webhooks.constructEvent).not.toHaveBeenCalled();
  });
});
