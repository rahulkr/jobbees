/**
 * License factories — for testing the per-category license verification (ADR 005).
 */

import { id } from './faker-config.js';
import { aTasker } from './users.js';

type LicenseStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'EXPIRED';

interface LicenseFields {
  id: string;
  userId: string;
  categoryId: string;
  licenseType: string;
  licenseNumber: string;
  issuingState: 'NSW' | 'VIC' | 'QLD' | 'WA' | 'SA' | 'TAS' | 'ACT' | 'NT';
  status: LicenseStatus;
  uploadedBlobUrl: string;
  expiresAt: Date;
  approvedAt: Date | null;
  approvedByAdminId: string | null;
  rejectedAt: Date | null;
  rejectionReason: string | null;
  registerCheckUrl: string | null;
  registerCheckedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

interface LicenseOverrides extends Partial<LicenseFields> {
  user?: { id: string };
}

/**
 * A pending plumbing license — awaiting admin review.
 */
export function aPendingPlumbingLicense(overrides: LicenseOverrides = {}): LicenseFields {
  const user = overrides.user ?? aTasker();
  const now = new Date();
  const { user: _u, ...rest } = overrides;
  return {
    id: id(),
    userId: user.id,
    categoryId: 'cat_test_plumbing',
    licenseType: 'plumber-nsw',
    licenseNumber: 'L123456',
    issuingState: 'NSW',
    status: 'PENDING',
    uploadedBlobUrl: 'https://test.blob.core.windows.net/licenses/test-plumbing-license.jpg',
    expiresAt: new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000),
    approvedAt: null,
    approvedByAdminId: null,
    rejectedAt: null,
    rejectionReason: null,
    registerCheckUrl: 'https://verify.licence.nsw.gov.au/test/L123456',
    registerCheckedAt: null,
    createdAt: now,
    updatedAt: now,
    ...rest,
  };
}

/**
 * An approved plumbing license — tasker can make offers on plumbing jobs.
 */
export function anApprovedPlumbingLicense(overrides: LicenseOverrides = {}): LicenseFields {
  const now = new Date();
  return aPendingPlumbingLicense({
    status: 'APPROVED',
    approvedAt: now,
    approvedByAdminId: id(),
    registerCheckedAt: now,
    ...overrides,
  });
}

/**
 * An expired license — tasker can NO LONGER make offers on plumbing jobs.
 */
export function anExpiredPlumbingLicense(overrides: LicenseOverrides = {}): LicenseFields {
  const past = new Date(Date.now() - 24 * 60 * 60 * 1000);
  return anApprovedPlumbingLicense({
    status: 'EXPIRED',
    expiresAt: past,
    ...overrides,
  });
}

/**
 * An approved Builder license — for the conditional Builder rule.
 */
export function anApprovedBuilderLicense(overrides: LicenseOverrides = {}): LicenseFields {
  return anApprovedPlumbingLicense({
    categoryId: 'cat_test_builder',
    licenseType: 'builder-nsw',
    licenseNumber: 'BL789012',
    registerCheckUrl: 'https://verify.licence.nsw.gov.au/test/BL789012',
    ...overrides,
  });
}
