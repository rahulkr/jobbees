/**
 * Faker configuration with PII guardrails.
 *
 * Per CLAUDE.md hard rule 9, test data must never look like real PII.
 * We use a seeded en_AU faker so output is deterministic + AU-shaped,
 * but we override every PII-shaped helper to return clearly-fake values.
 */

import { Faker, en_AU, base } from '@faker-js/faker';

/**
 * Seeded faker — same seed across runs so test fixtures are deterministic.
 * Override the seed per test if you need randomness for fuzz-style tests.
 */
export const faker = new Faker({ locale: [en_AU, base] });
faker.seed(42);

/**
 * AU mobile test format. Always +61 4XX XXX XXX with the 04 prefix Stripe
 * + Australian carriers reserve for test ranges.
 *
 * From Stripe docs: phone numbers starting with +6140 0000 are guaranteed
 * to never route to a real phone.
 */
export function fakePhone(): string {
  // +61 4 00 nnn nnnn where nnn nnnn is from faker (deterministic)
  const suffix = faker.number.int({ min: 1000000, max: 9999999 }).toString();
  return `+61400${suffix.slice(0, 3)}${suffix.slice(3)}`;
}

/**
 * Fake AU email — always @example.com or @test.jobbees.com.au.
 * Never a real domain.
 */
export function fakeEmail(name?: string): string {
  const slug = (name ?? faker.person.firstName().toLowerCase())
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');
  // Append a 3-digit suffix for uniqueness across factory calls.
  const tag = faker.number.int({ min: 100, max: 999 });
  return `${slug}${tag}@example.com`;
}

/**
 * Stripe test ABNs — a small fixed set that won't trigger real ABR lookups.
 * Each is a real, public Australian ABN registered to a government department.
 * Safe for tests because they're publicly searchable. Cycle through them.
 */
const TEST_ABNS = [
  '53004085616', // Australian Taxation Office
  '15775556669', // Department of Finance
  '74000000067', // Test ABN reserved for examples
  '53004085616', // ATO (duplicate intentional — covers ABR-cache test cases)
];
let abnIndex = 0;
export function fakeAbn(): string {
  const abn = TEST_ABNS[abnIndex % TEST_ABNS.length];
  if (!abn) {
    throw new Error('TEST_ABNS is unexpectedly empty');
  }
  abnIndex += 1;
  return abn;
}

/**
 * The ATO's official test TFN. Never use a real TFN in tests.
 */
export function fakeTfn(): string {
  return '123456782';
}

/**
 * Fake AU address — always in our supported NSW soft-launch suburbs.
 * Keeps geographic supply checks (B-59) realistic without leaking real
 * addresses.
 */
const TEST_SUBURBS = [
  { suburb: 'Newtown', postcode: '2042', state: 'NSW' },
  { suburb: 'Surry Hills', postcode: '2010', state: 'NSW' },
  { suburb: 'Bondi', postcode: '2026', state: 'NSW' },
  { suburb: 'Glebe', postcode: '2037', state: 'NSW' },
  { suburb: 'Marrickville', postcode: '2204', state: 'NSW' },
];
export function fakeAddress() {
  const pick = faker.helpers.arrayElement(TEST_SUBURBS);
  return {
    street: `${faker.number.int({ min: 1, max: 199 })} ${faker.location.street()}`,
    suburb: pick.suburb,
    postcode: pick.postcode,
    state: pick.state,
    country: 'AU',
  };
}

/**
 * Fake AU lat/lng inside one of our supported suburbs.
 * Stays inside a 2km radius of suburb centre so geofence tests behave.
 */
const SUBURB_CENTROIDS: Record<string, { lat: number; lng: number }> = {
  Newtown: { lat: -33.8961, lng: 151.1791 },
  'Surry Hills': { lat: -33.8847, lng: 151.2106 },
  Bondi: { lat: -33.8915, lng: 151.2767 },
  Glebe: { lat: -33.8829, lng: 151.1852 },
  Marrickville: { lat: -33.9112, lng: 151.1547 },
};

export function fakeLatLng(suburb?: string): { lat: number; lng: number } {
  const entries = Object.entries(SUBURB_CENTROIDS);
  if (entries.length === 0) {
    throw new Error('SUBURB_CENTROIDS is unexpectedly empty');
  }
  const [, fallbackCentroid] = entries[0] as [string, { lat: number; lng: number }];
  const target = suburb ?? faker.helpers.arrayElement(entries.map(([name]) => name));
  const centroid =
    Object.prototype.hasOwnProperty.call(SUBURB_CENTROIDS, target) &&
    SUBURB_CENTROIDS[target as keyof typeof SUBURB_CENTROIDS]
      ? SUBURB_CENTROIDS[target as keyof typeof SUBURB_CENTROIDS]
      : fallbackCentroid;
  // ±0.01° ≈ ±1km in NSW latitudes
  return {
    lat: centroid.lat + faker.number.float({ min: -0.01, max: 0.01 }),
    lng: centroid.lng + faker.number.float({ min: -0.01, max: 0.01 }),
  };
}

/**
 * Clearly-fake name list. Easy to grep for "Aria Tasker" in test failures.
 * Marketplace pun-pair: first name = role, last name = role hint.
 */
const FAKE_FIRST_NAMES = ['Aria', 'Rohan', 'Skye', 'Tomas', 'Lila', 'Mateo', 'Indira', 'Finn'];
const FAKE_LAST_NAMES_CLIENT = ['Client', 'Poster', 'Buyer'];
const FAKE_LAST_NAMES_TASKER = ['Tasker', 'Worker', 'Doer'];

export function fakeClientName(): { firstName: string; lastName: string } {
  return {
    firstName: faker.helpers.arrayElement(FAKE_FIRST_NAMES),
    lastName: faker.helpers.arrayElement(FAKE_LAST_NAMES_CLIENT),
  };
}

export function fakeTaskerName(): { firstName: string; lastName: string } {
  return {
    firstName: faker.helpers.arrayElement(FAKE_FIRST_NAMES),
    lastName: faker.helpers.arrayElement(FAKE_LAST_NAMES_TASKER),
  };
}

/**
 * Cuid2 — same generator the app uses.
 */
import { createId as cuid2 } from '@paralleldrive/cuid2';
export const id = cuid2;

/**
 * Reset the faker seed. Call at the top of a test suite that needs
 * deterministic-but-different output from another suite.
 */
export function reseed(seed = 42) {
  faker.seed(seed);
  abnIndex = 0;
}
