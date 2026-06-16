/**
 * Payment factories — Payment state machine:
 *
 *   AUTHORISED → CAPTURED → REFUNDED | PARTIAL_REFUNDED
 *              ↘ RE_AUTH_REQUIRED → AUTHORISED | SETUP_ONLY
 *              ↘ FAILED
 *              ↘ VOIDED
 *
 *   SETUP_ONLY (from SetupIntent path) → CAPTURED
 */

import { id } from './faker-config.js';
import { aClient } from './users.js';
import { aJob } from './jobs.js';

type PaymentState =
  | 'AUTHORISED'
  | 'CAPTURED'
  | 'RE_AUTH_REQUIRED'
  | 'SETUP_ONLY'
  | 'FAILED'
  | 'VOIDED'
  | 'REFUNDED'
  | 'PARTIAL_REFUNDED';

interface PaymentFields {
  id: string;
  jobId: string;
  offerId: string;
  clientId: string;
  amountCents: number;
  currency: string;
  state: PaymentState;
  stripePaymentIntentId: string | null;
  stripeSetupIntentId: string | null;
  stripePaymentMethodId: string;
  capturedAt: Date | null;
  expiresAt: Date | null;
  voidedAt: Date | null;
  refundedCents: number;
  applicationFeeCents: number;
  // dispute-hold state per B-56
  heldIndefinitely: boolean;
  // payout-ready gate per B-56
  payoutReady: boolean;
  createdAt: Date;
  updatedAt: Date;
}

interface PaymentOverrides extends Partial<PaymentFields> {
  job?: { id: string };
  offer?: { id: string };
  client?: { id: string };
}

/**
 * An authorised payment (Mode 1, manual capture window open).
 * Default budget = $84, app fee = 15% = $12.60 = 1260c
 */
export function anAuthorisedPayment(overrides: PaymentOverrides = {}): PaymentFields {
  const job = overrides.job ?? aJob();
  const client = overrides.client ?? aClient();
  const now = new Date();
  const { job: _j, offer: _o, client: _c, ...rest } = overrides;
  return {
    id: id(),
    jobId: job.id,
    offerId: overrides.offer?.id ?? id(),
    clientId: client.id,
    amountCents: 8400,
    currency: 'AUD',
    state: 'AUTHORISED',
    stripePaymentIntentId: `pi_test_${id().slice(0, 14)}`,
    stripeSetupIntentId: null,
    stripePaymentMethodId: `pm_test_${id().slice(0, 14)}`,
    capturedAt: null,
    expiresAt: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000), // 7d Stripe window
    voidedAt: null,
    refundedCents: 0,
    applicationFeeCents: 1260, // 15% of 8400
    heldIndefinitely: false,
    payoutReady: false,
    createdAt: now,
    updatedAt: now,
    ...rest,
  };
}

/**
 * A captured payment — money has moved, Tasker is owed payout.
 */
export function aCapturedPayment(overrides: PaymentOverrides = {}): PaymentFields {
  return anAuthorisedPayment({
    state: 'CAPTURED',
    capturedAt: new Date(),
    payoutReady: true,
    ...overrides,
  });
}

/**
 * A payment in re-auth-required state (approaching 7d expiry).
 */
export function aReAuthRequiredPayment(overrides: PaymentOverrides = {}): PaymentFields {
  const now = new Date();
  // expiresAt within 6 hours triggers the re-auth cron
  return anAuthorisedPayment({
    state: 'RE_AUTH_REQUIRED',
    expiresAt: new Date(now.getTime() + 6 * 60 * 60 * 1000),
    ...overrides,
  });
}

/**
 * A SetupIntent-only payment — used for jobs scheduled > 7 days out.
 */
export function aSetupOnlyPayment(overrides: PaymentOverrides = {}): PaymentFields {
  return anAuthorisedPayment({
    state: 'SETUP_ONLY',
    stripePaymentIntentId: null,
    stripeSetupIntentId: `seti_test_${id().slice(0, 14)}`,
    expiresAt: null, // SetupIntent doesn't expire
    ...overrides,
  });
}

/**
 * A fully refunded payment.
 */
export function aRefundedPayment(overrides: PaymentOverrides = {}): PaymentFields {
  return aCapturedPayment({
    state: 'REFUNDED',
    refundedCents: 8400,
    ...overrides,
  });
}

/**
 * A partially refunded payment.
 */
export function aPartialRefundedPayment(overrides: PaymentOverrides = {}): PaymentFields {
  return aCapturedPayment({
    state: 'PARTIAL_REFUNDED',
    refundedCents: 2000, // $20 partial refund
    ...overrides,
  });
}

/**
 * A held-indefinitely payment (dispute open per B-56).
 * Payout is locked until dispute resolves.
 */
export function aHeldPayment(overrides: PaymentOverrides = {}): PaymentFields {
  return aCapturedPayment({
    heldIndefinitely: true,
    payoutReady: false,
    ...overrides,
  });
}
