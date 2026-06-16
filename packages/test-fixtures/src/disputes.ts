/**
 * Dispute factories — covering the Tier-0 mediator flow + escalation.
 */

import { faker, id } from './faker-config.js';
import { aClient } from './users.js';
import { aJob } from './jobs.js';

type DisputeState = 'FILED' | 'AI_REVIEWING' | 'AI_PROPOSED' | 'RESOLVED' | 'ESCALATED';
type DisputeResolutionType =
  | 'FULL_RELEASE_TO_TASKER'
  | 'PARTIAL_RELEASE'
  | 'REFUND_TO_CLIENT'
  | 'NO_ACTION';

interface DisputeFields {
  id: string;
  jobId: string;
  paymentId: string;
  initiatorId: string;
  initiatorRole: 'CLIENT' | 'TASKER';
  reason: string;
  state: DisputeState;
  tier0ProposalId: string | null;
  tier0ResolvedAt: Date | null;
  escalatedAt: Date | null;
  escalatedToAdminId: string | null;
  resolvedAt: Date | null;
  resolutionType: DisputeResolutionType | null;
  resolutionAmountCents: number | null;
  createdAt: Date;
  updatedAt: Date;
}

const TEST_DISPUTE_REASONS = [
  'Tasker did not arrive on the agreed day',
  'Work was incomplete — only half the panels were replaced',
  'Tasker damaged my property during the job',
  'Quality below what was discussed',
];

interface DisputeOverrides extends Partial<DisputeFields> {
  job?: { id: string };
  initiator?: { id: string };
  paymentId?: string;
}

/**
 * A freshly filed dispute — Tier-0 mediator hasn't run yet.
 */
export function aDispute(overrides: DisputeOverrides = {}): DisputeFields {
  const job = overrides.job ?? aJob();
  const initiator = overrides.initiator ?? aClient();
  const now = new Date();
  const { job: _j, initiator: _i, ...rest } = overrides;
  return {
    id: id(),
    jobId: job.id,
    paymentId: overrides.paymentId ?? id(),
    initiatorId: initiator.id,
    initiatorRole: 'CLIENT',
    reason: faker.helpers.arrayElement(TEST_DISPUTE_REASONS),
    state: 'FILED',
    tier0ProposalId: null,
    tier0ResolvedAt: null,
    escalatedAt: null,
    escalatedToAdminId: null,
    resolvedAt: null,
    resolutionType: null,
    resolutionAmountCents: null,
    createdAt: now,
    updatedAt: now,
    ...rest,
  };
}

/**
 * A dispute resolved by Tier-0 mediator with a partial release.
 */
export function aResolvedDispute(overrides: DisputeOverrides = {}): DisputeFields {
  const now = new Date();
  return aDispute({
    state: 'RESOLVED',
    tier0ProposalId: id(),
    tier0ResolvedAt: now,
    resolvedAt: now,
    resolutionType: 'PARTIAL_RELEASE',
    resolutionAmountCents: 4200, // 50% of $84
    ...overrides,
  });
}

/**
 * An escalated dispute — Tier-0 was rejected, human admin is reviewing.
 */
export function anEscalatedDispute(overrides: DisputeOverrides = {}): DisputeFields {
  return aDispute({
    state: 'ESCALATED',
    tier0ProposalId: id(),
    tier0ResolvedAt: new Date(),
    escalatedAt: new Date(),
    ...overrides,
  });
}
