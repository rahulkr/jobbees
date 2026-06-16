/**
 * Job factories — covering every status in the state machine.
 *
 * Job state machine: DRAFT → PUBLISHED → OFFERING → ACCEPTED → IN_PROGRESS → COMPLETED
 *                                                            ↘ CANCELLED
 *                                                            ↘ DISPUTED
 */

import { faker, fakeAddress, fakeLatLng, id } from './faker-config.js';
import { aClient } from './users.js';

type JobStatus =
  | 'DRAFT'
  | 'PUBLISHED'
  | 'OFFERING'
  | 'ACCEPTED'
  | 'IN_PROGRESS'
  | 'COMPLETED'
  | 'CANCELLED'
  | 'DISPUTED';

interface JobFields {
  id: string;
  clientId: string;
  title: string;
  slug: string;
  description: string;
  categoryId: string;
  status: JobStatus;
  budgetCents: number;
  currency: string;
  // location
  street: string;
  suburb: string;
  postcode: string;
  state: string;
  countryCode: string;
  latitude: number;
  longitude: number;
  // timing
  scheduledAt: Date;
  durationMinutes: number | null;
  // AI
  extractedFields: object | null;
  embeddingHash: string | null;
  // workflow
  publishedAt: Date | null;
  acceptedAt: Date | null;
  acceptedOfferId: string | null;
  completedAt: Date | null;
  cancelledAt: Date | null;
  cancelledByUserId: string | null;
  // soft delete / audit
  deletedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

// A small fixed set of categories used in tests.
// Real category seeds live in packages/prisma/seed.ts.
export const TEST_CATEGORIES = {
  cleaning: { id: 'cat_test_cleaning', requiresLicense: false, name: 'Cleaning' },
  handyman: { id: 'cat_test_handyman', requiresLicense: false, name: 'Handyman' },
  plumbing: { id: 'cat_test_plumbing', requiresLicense: true, name: 'Plumbing' },
  electrical: { id: 'cat_test_electrical', requiresLicense: true, name: 'Electrical' },
  builder: {
    id: 'cat_test_builder',
    requiresLicense: false,
    licenseRequiredOverCents: 500000,
    name: 'Builder',
  },
} as const;

const TEST_JOB_TITLES = [
  'Assemble Ikea Hemnes bookshelf',
  'Fix leaking kitchen tap',
  'Mount 55-inch TV on plasterboard wall',
  'Clean 2-bed apartment before inspection',
  'Move furniture from old place to new',
  'Replace 3 broken fence panels',
  'Help build raised garden beds',
];

const TEST_JOB_DESCRIPTIONS = [
  'About 2 hours of work, tools provided.',
  'Need someone with their own tools — happy to pay materials separately.',
  'Saturday morning works best, weekday evenings also fine.',
  'Quote and timing flexible, just need it done this week.',
];

interface JobOverrides extends Partial<JobFields> {
  client?: { id: string };
  category?: { id: string };
}

/**
 * A standard published job — open for offers, no offers yet.
 */
export function aJob(overrides: JobOverrides = {}): JobFields {
  const client = overrides.client ?? aClient();
  const category = overrides.category ?? TEST_CATEGORIES.cleaning;
  const address = fakeAddress();
  const latlng = fakeLatLng(address.suburb);
  const title = faker.helpers.arrayElement(TEST_JOB_TITLES);
  const now = new Date();
  const { client: _c, category: _cat, ...rest } = overrides;
  return {
    id: id(),
    clientId: client.id,
    title,
    slug: title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, ''),
    description: faker.helpers.arrayElement(TEST_JOB_DESCRIPTIONS),
    categoryId: category.id,
    status: 'OFFERING',
    budgetCents: 8400, // $84 — deterministic, easy to assert
    currency: 'AUD',
    street: address.street,
    suburb: address.suburb,
    postcode: address.postcode,
    state: address.state,
    countryCode: 'AU',
    latitude: latlng.lat,
    longitude: latlng.lng,
    scheduledAt: faker.date.soon({ days: 3 }),
    durationMinutes: 120,
    extractedFields: null,
    embeddingHash: null,
    publishedAt: now,
    acceptedAt: null,
    acceptedOfferId: null,
    completedAt: null,
    cancelledAt: null,
    cancelledByUserId: null,
    deletedAt: null,
    createdAt: now,
    updatedAt: now,
    ...rest,
  };
}

/**
 * A draft job — used to test the post-then-signup flow in S3.
 */
export function aDraftJob(overrides: JobOverrides = {}): JobFields {
  return aJob({
    status: 'DRAFT',
    publishedAt: null,
    ...overrides,
  });
}

/**
 * A scheduled-far-future job — triggers SetupIntent (Mode 2) payment path.
 */
export function aScheduledFutureJob(overrides: JobOverrides = {}): JobFields {
  return aJob({
    scheduledAt: faker.date.soon({ days: 14 }), // > 7d triggers Mode 2
    ...overrides,
  });
}

/**
 * An accepted job — for testing the messaging + payment-auth flows.
 */
export function anAcceptedJob(overrides: JobOverrides & { acceptedOfferId: string }): JobFields {
  return aJob({
    status: 'ACCEPTED',
    acceptedAt: new Date(),
    ...overrides,
  });
}

/**
 * A completed job — for testing reviews + dispute window.
 */
export function aCompletedJob(overrides: JobOverrides & { acceptedOfferId: string }): JobFields {
  return aJob({
    status: 'COMPLETED',
    acceptedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    completedAt: new Date(),
    ...overrides,
  });
}

/**
 * A plumbing job — triggers the unconditional license rule.
 * Tasker without an approved plumbing license cannot offer.
 */
export function aPlumbingJob(overrides: JobOverrides = {}): JobFields {
  return aJob({ ...overrides, category: TEST_CATEGORIES.plumbing });
}

/**
 * A builder job over $5,000 — triggers the conditional Builder license rule.
 * Tasker without an approved builder license cannot offer.
 */
export function aBuilderJobOver5k(overrides: JobOverrides = {}): JobFields {
  return aJob({
    budgetCents: 750000, // $7,500 — well above the 500000c threshold
    category: TEST_CATEGORIES.builder,
    ...overrides,
  });
}

/**
 * A builder job under $5,000 — does NOT trigger license rule.
 * Used to test the boundary condition.
 */
export function aBuilderJobUnder5k(overrides: JobOverrides = {}): JobFields {
  return aJob({
    budgetCents: 400000, // $4,000 — under the 500000c threshold
    category: TEST_CATEGORIES.builder,
    ...overrides,
  });
}
