/**
 * User factories — Client, Tasker, Admin, Super Admin.
 *
 * Returns plain JS objects shaped like the Prisma User model.
 * Persist via `prisma.user.create({ data: aClient() })` if needed.
 */

import {
  faker,
  fakePhone,
  fakeEmail,
  fakeClientName,
  fakeTaskerName,
  fakeAbn,
  id,
} from './faker-config.js';

type UserRole = 'CLIENT' | 'TASKER' | 'ADMIN' | 'SUPER_ADMIN';
type KycStatus = 'NOT_STARTED' | 'PENDING' | 'APPROVED' | 'REJECTED' | 'REVIEW';

interface BaseUserFields {
  id: string;
  email: string;
  emailVerified: boolean;
  phone: string;
  phoneVerified: boolean;
  passwordHash: string | null;
  firstName: string;
  lastName: string;
  role: UserRole;
  countryCode: string;
  kycStatus: KycStatus;
  kycVerifiedAt: Date | null;
  stripeConnectAccountId: string | null;
  abn: string | null;
  abnVerifiedAt: Date | null;
  abrBusinessName: string | null;
  suspendedAt: Date | null;
  suspendedReason: string | null;
  bannedAt: Date | null;
  bannedReason: string | null;
  deletedAt: Date | null;
  anonymisedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

type ClientOverrides = Partial<BaseUserFields>;
type TaskerOverrides = Partial<BaseUserFields>;
type AdminOverrides = Partial<BaseUserFields>;

/**
 * A standard Client — email-verified, phone optional, no Stripe Connect,
 * no ABN. KYC not applicable (clients don't go through Stripe Connect).
 */
export function aClient(overrides: ClientOverrides = {}): BaseUserFields {
  const name = fakeClientName();
  const now = new Date();
  return {
    id: id(),
    email: fakeEmail(name.firstName),
    emailVerified: true,
    phone: fakePhone(),
    phoneVerified: false, // clients don't OTP
    // argon2id hash of "test-password" — never use real bcrypt/argon hashes in tests
    passwordHash: '$argon2id$v=19$m=65536,t=3,p=4$test$hash',
    firstName: name.firstName,
    lastName: name.lastName,
    role: 'CLIENT',
    countryCode: 'AU',
    kycStatus: 'NOT_STARTED',
    kycVerifiedAt: null,
    stripeConnectAccountId: null,
    abn: null,
    abnVerifiedAt: null,
    abrBusinessName: null,
    suspendedAt: null,
    suspendedReason: null,
    bannedAt: null,
    bannedReason: null,
    deletedAt: null,
    anonymisedAt: null,
    createdAt: now,
    updatedAt: now,
    ...overrides,
  };
}

/**
 * A standard Tasker — phone-verified, KYC approved via Stripe Connect,
 * has Stripe Connect account, has ABN.
 *
 * For an unverified tasker (e.g., testing held-funds banner), use
 * `aTasker({ kycStatus: 'PENDING', stripeConnectAccountId: null })`.
 */
export function aTasker(overrides: TaskerOverrides = {}): BaseUserFields {
  const name = fakeTaskerName();
  const now = new Date();
  return {
    id: id(),
    email: fakeEmail(name.firstName),
    emailVerified: true,
    phone: fakePhone(),
    phoneVerified: true, // taskers MUST OTP
    passwordHash: '$argon2id$v=19$m=65536,t=3,p=4$test$hash',
    firstName: name.firstName,
    lastName: name.lastName,
    role: 'TASKER',
    countryCode: 'AU',
    kycStatus: 'APPROVED',
    kycVerifiedAt: now,
    stripeConnectAccountId: `acct_test_${id().slice(0, 14)}`,
    abn: fakeAbn(),
    abnVerifiedAt: now,
    abrBusinessName: `${name.firstName} ${name.lastName} Services Pty Ltd`,
    suspendedAt: null,
    suspendedReason: null,
    bannedAt: null,
    bannedReason: null,
    deletedAt: null,
    anonymisedAt: null,
    createdAt: now,
    updatedAt: now,
    ...overrides,
  };
}

/**
 * Tasker in the "held funds" state — Connect onboarding incomplete.
 * Use this when testing the held-funds banner or the offer-acceptance gate.
 */
export function aTaskerWithHeldFunds(overrides: TaskerOverrides = {}): BaseUserFields {
  return aTasker({
    kycStatus: 'PENDING',
    stripeConnectAccountId: null,
    kycVerifiedAt: null,
    ...overrides,
  });
}

/**
 * Tasker without an ABN — triggers the RCTI flow on payouts.
 */
export function aTaskerWithoutAbn(overrides: TaskerOverrides = {}): BaseUserFields {
  return aTasker({
    abn: null,
    abnVerifiedAt: null,
    abrBusinessName: null,
    ...overrides,
  });
}

/**
 * Suspended tasker — for auto-suspend (B-57) + reinstatement (AP-58) tests.
 */
export function aSuspendedTasker(
  reason = '3 disputes lost',
  overrides: TaskerOverrides = {},
): BaseUserFields {
  const now = new Date();
  return aTasker({
    suspendedAt: now,
    suspendedReason: reason,
    ...overrides,
  });
}

/**
 * Standard Admin — operational privileges, NOT super-admin.
 * Cannot trigger refunds > $1k or hard delete (requires AP-56 approval).
 */
export function anAdmin(overrides: AdminOverrides = {}): BaseUserFields {
  const name = {
    firstName: faker.helpers.arrayElement(['Sarah', 'Marcus', 'Priya']),
    lastName: 'Admin',
  };
  const now = new Date();
  return {
    id: id(),
    email: `${name.firstName.toLowerCase()}.admin@test.jobbees.com.au`,
    emailVerified: true,
    phone: fakePhone(),
    phoneVerified: true,
    passwordHash: '$argon2id$v=19$m=65536,t=3,p=4$test$hash',
    firstName: name.firstName,
    lastName: name.lastName,
    role: 'ADMIN',
    countryCode: 'AU',
    kycStatus: 'NOT_STARTED',
    kycVerifiedAt: null,
    stripeConnectAccountId: null,
    abn: null,
    abnVerifiedAt: null,
    abrBusinessName: null,
    suspendedAt: null,
    suspendedReason: null,
    bannedAt: null,
    bannedReason: null,
    deletedAt: null,
    anonymisedAt: null,
    createdAt: now,
    updatedAt: now,
    ...overrides,
  };
}

/**
 * Super Admin — for two-person approval (AP-56) tests + destructive operations.
 */
export function aSuperAdmin(overrides: AdminOverrides = {}): BaseUserFields {
  return anAdmin({
    role: 'SUPER_ADMIN',
    firstName: 'Saiju',
    lastName: 'Founder',
    email: 'saiju@test.jobbees.com.au',
    ...overrides,
  });
}
