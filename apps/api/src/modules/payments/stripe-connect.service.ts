import {
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { ConnectStatus, UserRole } from '@jobbees/prisma';
import { AuditLogService } from '../../common/audit/audit-log.service';
import { PrismaService } from '../../prisma/prisma.service';
import { STRIPE_CLIENT } from './stripe.constants';

// Stripe's CJS typings only surface the instance type through the default
// import, so derive the resource types we use from the SDK method signatures.
type StripeClient = Stripe.Stripe;
type StripeAccount = Awaited<ReturnType<StripeClient['accounts']['retrieve']>>;
export type StripeEvent = ReturnType<StripeClient['webhooks']['constructEvent']>;

/** Request context for the audit trail (set by the controller). */
export interface ActorContext {
  ipAddress?: string | null;
  userAgent?: string | null;
}

export interface ConnectStatusResult {
  status: ConnectStatus;
  payoutsEnabled: boolean;
  detailsSubmitted: boolean;
}

/**
 * Stripe Connect Express onboarding for taskers (ADR 005: Connect handles legal
 * identity, so there is no separate Identity step). This slice covers onboarding
 * + status only; capture/payout/GST/RCTI land with real job payments.
 *
 * The SDK lives behind this service (stripe-payment skill rule 1); controllers
 * never touch it directly. Every state change is audited.
 */
@Injectable()
export class StripeConnectService {
  private readonly logger = new Logger(StripeConnectService.name);

  constructor(
    @Inject(STRIPE_CLIENT) private readonly stripe: StripeClient | null,
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly audit: AuditLogService,
  ) {}

  private client(): StripeClient {
    if (!this.stripe) {
      throw new ServiceUnavailableException('Payments are not configured');
    }
    return this.stripe;
  }

  /**
   * Creates the Express account on first call (persisting the id + flipping to
   * PENDING), then returns a fresh hosted onboarding link. Account creation is
   * idempotent on the Stripe side via a per-user key, so retries don't create
   * duplicate accounts.
   */
  async startOnboarding(userId: string, ctx: ActorContext = {}): Promise<{ url: string }> {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, deletedAt: null },
    });
    if (!user) throw new NotFoundException('User not found');
    if (user.role !== UserRole.TASKER) {
      throw new ForbiddenException('Only taskers set up payouts');
    }

    let accountId = user.stripeAccountId;
    if (!accountId) {
      const account = await this.client().accounts.create(
        {
          type: 'express',
          country: user.countryCode,
          email: user.email,
          capabilities: { transfers: { requested: true } },
          business_type: 'individual',
          // Prefill what we already hold so the hosted onboarding form is
          // shorter. Stripe does not re-ask for prefilled data (the tasker only
          // confirms it). We hold name/email/phone but NOT DOB or address, so
          // those remain the tasker's to enter (the regulatory KYC floor).
          // Transfers-only accounts collect no business/website profile (the
          // tasker isn't the merchant), so there's nothing to prefill there —
          // their only outstanding requirement is an ID verification document.
          individual: {
            first_name: user.firstName,
            last_name: user.lastName,
            email: user.email,
            ...(user.phone ? { phone: user.phone } : {}),
          },
          metadata: { userId },
        },
        { idempotencyKey: `connect-create-${userId}` },
      );
      accountId = account.id;
      await this.prisma.user.update({
        where: { id: userId },
        data: {
          stripeAccountId: accountId,
          connectStatus: ConnectStatus.PENDING,
        },
      });
      await this.audit.record({
        actorId: userId,
        action: 'connect.account_created',
        resourceType: 'User',
        resourceId: userId,
        diff: { connectStatus: ConnectStatus.PENDING },
        ipAddress: ctx.ipAddress,
        userAgent: ctx.userAgent,
      });
    }

    const base = this.config.get<string>('STRIPE_CONNECT_RETURN_URL', '');
    const link = await this.client().accountLinks.create({
      account: accountId,
      refresh_url: `${base}?refresh=1`,
      return_url: base,
      type: 'account_onboarding',
    });
    return { url: link.url };
  }

  /** Pulls live account state from Stripe, persists any change, returns it. */
  async syncStatus(userId: string): Promise<ConnectStatusResult> {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, deletedAt: null },
    });
    if (!user) throw new NotFoundException('User not found');
    if (!user.stripeAccountId) {
      return {
        status: ConnectStatus.NOT_STARTED,
        payoutsEnabled: false,
        detailsSubmitted: false,
      };
    }
    const account = await this.client().accounts.retrieve(user.stripeAccountId);
    return this.applyAccount(user.id, user.connectStatus, account);
  }

  /** Verifies a webhook signature against the raw request body. */
  constructEvent(rawBody: Buffer, signature: string): StripeEvent {
    const secret = this.config.get<string>('STRIPE_WEBHOOK_SECRET', '');
    if (!secret) {
      throw new ServiceUnavailableException('Webhooks are not configured');
    }
    return this.client().webhooks.constructEvent(rawBody, signature, secret);
  }

  /**
   * Dispatches a verified webhook event. Idempotent: re-applying the same
   * status is a no-op, so Stripe retries are safe.
   */
  async handleEvent(event: StripeEvent): Promise<void> {
    switch (event.type) {
      case 'account.updated':
        await this.handleAccountUpdated(event.data.object as StripeAccount);
        break;
      default:
        this.logger.debug(`Unhandled Stripe event: ${event.type}`);
    }
  }

  private async handleAccountUpdated(account: StripeAccount): Promise<void> {
    const user = await this.prisma.user.findFirst({
      where: { stripeAccountId: account.id, deletedAt: null },
    });
    if (!user) {
      this.logger.warn('Received account.updated for an unknown Connect account');
      return;
    }
    await this.applyAccount(user.id, user.connectStatus, account);
  }

  private async applyAccount(
    userId: string,
    current: ConnectStatus,
    account: StripeAccount,
  ): Promise<ConnectStatusResult> {
    const status = this.mapStatus(account);
    if (status !== current) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { connectStatus: status },
      });
      await this.audit.record({
        actorId: userId,
        action: 'connect.status_changed',
        resourceType: 'User',
        resourceId: userId,
        diff: { from: current, to: status },
      });
    }
    return {
      status,
      payoutsEnabled: account.payouts_enabled ?? false,
      detailsSubmitted: account.details_submitted ?? false,
    };
  }

  /**
   * Maps a Stripe account to our [ConnectStatus]. Payouts enabled is the bar
   * for COMPLETE; a `rejected.*` disabled reason is RESTRICTED; anything else
   * mid-onboarding stays PENDING.
   */
  private mapStatus(account: StripeAccount): ConnectStatus {
    if (account.payouts_enabled) return ConnectStatus.COMPLETE;
    const reason = account.requirements?.disabled_reason ?? null;
    if (reason && reason.startsWith('rejected')) return ConnectStatus.RESTRICTED;
    return ConnectStatus.PENDING;
  }
}
