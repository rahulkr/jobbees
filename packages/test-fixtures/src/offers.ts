/**
 * Offer factories — Offer state machine: PENDING → ACCEPTED | WITHDRAWN | DECLINED | EXPIRED
 */

import { faker, id } from './faker-config.js';
import { aTasker } from './users.js';
import { aJob } from './jobs.js';

type OfferStatus = 'PENDING' | 'ACCEPTED' | 'WITHDRAWN' | 'DECLINED' | 'EXPIRED';

interface OfferFields {
  id: string;
  jobId: string;
  taskerId: string;
  amountCents: number;
  currency: string;
  message: string;
  etaMinutes: number;
  status: OfferStatus;
  expiresAt: Date;
  acceptedAt: Date | null;
  withdrawnAt: Date | null;
  declinedAt: Date | null;
  expiredAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

const TEST_OFFER_MESSAGES = [
  "I'm available Saturday morning — happy to do it for the budget.",
  "I've done similar jobs locally. Can be there by 9am.",
  "I'll bring my own tools. Quote includes basic materials.",
  'Available this week, flexible on timing.',
];

interface OfferOverrides extends Partial<OfferFields> {
  job?: { id: string };
  tasker?: { id: string };
}

/**
 * A standard pending offer — under budget by a small margin.
 */
export function anOffer(overrides: OfferOverrides = {}): OfferFields {
  const job = overrides.job ?? aJob();
  const tasker = overrides.tasker ?? aTasker();
  const now = new Date();
  const { job: _j, tasker: _t, ...rest } = overrides;
  return {
    id: id(),
    jobId: job.id,
    taskerId: tasker.id,
    amountCents: 8000, // $80 — slightly under the $84 default job budget
    currency: 'AUD',
    message: faker.helpers.arrayElement(TEST_OFFER_MESSAGES),
    etaMinutes: 60,
    status: 'PENDING',
    expiresAt: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000), // 7d
    acceptedAt: null,
    withdrawnAt: null,
    declinedAt: null,
    expiredAt: null,
    createdAt: now,
    updatedAt: now,
    ...rest,
  };
}

/**
 * An accepted offer — for testing payment-auth flows.
 */
export function anAcceptedOffer(overrides: OfferOverrides = {}): OfferFields {
  return anOffer({
    status: 'ACCEPTED',
    acceptedAt: new Date(),
    ...overrides,
  });
}

/**
 * A withdrawn offer — tasker pulled it before client accepted.
 */
export function aWithdrawnOffer(overrides: OfferOverrides = {}): OfferFields {
  return anOffer({
    status: 'WITHDRAWN',
    withdrawnAt: new Date(),
    ...overrides,
  });
}

/**
 * An expired offer — passed the expiresAt without being accepted/withdrawn.
 */
export function anExpiredOffer(overrides: OfferOverrides = {}): OfferFields {
  const past = new Date(Date.now() - 24 * 60 * 60 * 1000);
  return anOffer({
    status: 'EXPIRED',
    expiresAt: past,
    expiredAt: past,
    ...overrides,
  });
}
