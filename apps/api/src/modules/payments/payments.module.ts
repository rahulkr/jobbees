import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { ConnectController } from './connect.controller';
import { STRIPE_CLIENT } from './stripe.constants';
import { StripeConnectService } from './stripe-connect.service';
import { StripeWebhooksController } from './stripe-webhooks.controller';

/**
 * Payments. Sprint 2 lands Stripe Connect Express onboarding for taskers;
 * PaymentIntent capture, payouts, refunds, GST + RCTI join later.
 *
 * The Stripe client is null when STRIPE_SECRET_KEY is unset, so the app boots
 * without payments configured; the service surfaces a clear 503 if used.
 */
@Module({
  controllers: [ConnectController, StripeWebhooksController],
  providers: [
    StripeConnectService,
    {
      provide: STRIPE_CLIENT,
      inject: [ConfigService],
      useFactory: (config: ConfigService): Stripe.Stripe | null => {
        const key = config.get<string>('STRIPE_SECRET_KEY', '');
        return key ? new Stripe(key) : null;
      },
    },
  ],
  exports: [StripeConnectService],
})
export class PaymentsModule {}
