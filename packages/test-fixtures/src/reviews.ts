/**
 * Review factories — blind reveal flow.
 *
 * Reviews are written by both sides after a job completes but stay hidden
 * (visibleAt: null) until BOTH submit OR the 14-day timeout fires.
 */

import { faker, id } from './faker-config.js';
import { aClient, aTasker } from './users.js';

interface ReviewFields {
  id: string;
  jobId: string;
  reviewerId: string;
  reviewerRole: 'CLIENT' | 'TASKER';
  revieweeId: string;
  rating: number; // 1-5
  body: string;
  visibleAt: Date | null; // null = hidden (blind reveal pending)
  response: string | null;
  responseAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  reportedAt: Date | null;
  reportedReason: string | null;
  removedAt: Date | null;
  removedByAdminId: string | null;
  // B-41 review authenticity scoring
  authenticityScore: number | null; // 0-1
  authenticityFlags: string[];
}

const TEST_REVIEW_BODIES = [
  'Great work, would hire again. Arrived on time and finished early.',
  'Communication was clear throughout. The quality was solid.',
  "Solid job. Tasker came prepared, didn't need to chase anything.",
  'Job done well. Will use this platform again.',
];

interface ReviewOverrides extends Partial<ReviewFields> {
  reviewer?: { id: string };
  reviewee?: { id: string };
  job?: { id: string };
}

/**
 * A blind review — written but not yet visible to the other side.
 */
export function aBlindReview(overrides: ReviewOverrides = {}): ReviewFields {
  const reviewer = overrides.reviewer ?? aClient();
  const reviewee = overrides.reviewee ?? aTasker();
  const now = new Date();
  const { reviewer: _r, reviewee: _re, job: _j, ...rest } = overrides;
  return {
    id: id(),
    jobId: overrides.job?.id ?? id(),
    reviewerId: reviewer.id,
    reviewerRole: 'CLIENT',
    revieweeId: reviewee.id,
    rating: 5,
    body: faker.helpers.arrayElement(TEST_REVIEW_BODIES),
    visibleAt: null, // blind
    response: null,
    responseAt: null,
    createdAt: now,
    updatedAt: now,
    reportedAt: null,
    reportedReason: null,
    removedAt: null,
    removedByAdminId: null,
    authenticityScore: null,
    authenticityFlags: [],
    ...rest,
  };
}

/**
 * A revealed review — both parties have submitted OR 14-day timeout fired.
 */
export function aRevealedReview(overrides: ReviewOverrides = {}): ReviewFields {
  return aBlindReview({
    visibleAt: new Date(),
    authenticityScore: 0.95, // high authenticity by default
    ...overrides,
  });
}

/**
 * A suspicious review — B-41 review authenticity scoring flagged it.
 * For testing the review moderation queue.
 */
export function aSuspiciousReview(overrides: ReviewOverrides = {}): ReviewFields {
  return aRevealedReview({
    authenticityScore: 0.25, // low — looks LLM-generated or collusive
    authenticityFlags: ['gpt-phrasing-anomaly', 'burst-pattern'],
    ...overrides,
  });
}

/**
 * A reported review — flagged by the other party for moderation.
 */
export function aReportedReview(overrides: ReviewOverrides = {}): ReviewFields {
  return aRevealedReview({
    reportedAt: new Date(),
    reportedReason: 'Contains false claims about the work',
    ...overrides,
  });
}
