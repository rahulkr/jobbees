/**
 * @jobbees/test-fixtures — Named factory functions for test data.
 *
 * Usage:
 *   import { aClient, aTasker, aJob, anOffer, aCapturedPayment } from '@jobbees/test-fixtures';
 *
 *   const client = aClient();
 *   const tasker = aTasker({ kycStatus: 'APPROVED' });
 *   const job = aJob({ client });
 *   const offer = anOffer({ job, tasker });
 *
 * See README.md for the full pattern.
 * See faker-config.ts for the PII guardrails enforced on all factories.
 */

export * from './faker-config.js';
export * from './users.js';
export * from './jobs.js';
export * from './offers.js';
export * from './payments.js';
export * from './disputes.js';
export * from './reviews.js';
export * from './licenses.js';
