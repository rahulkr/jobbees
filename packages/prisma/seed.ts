/**
 * JOBBees — Database seed
 *
 * Run with: pnpm db:seed
 *
 * Creates a usable local development environment:
 * - 1 super admin user
 * - 5 test posters, 10 test taskers (KYC stub'd to APPROVED)
 * - Country (AU only at MVP)
 * - Categories (transactional, with parent/child hierarchy)
 * - 20 sample tasks across categories
 * - A few sample bids
 *
 * Do NOT seed prod-like volumes — keep local dev fast. Use Faker for realism.
 */
// Seed runs as a standalone `tsx` process, so it must load .env files itself —
// prisma.config.ts only loads them for the prisma CLI process.
import path from 'node:path';
import { config as loadEnv } from 'dotenv';
const repoRoot = path.resolve(__dirname, '..', '..');
loadEnv({ path: path.join(repoRoot, '.env.local') });
loadEnv({ path: path.join(repoRoot, '.env') });

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL is not set. See prisma.config.ts for env loading.');
}

import {
  PrismaClient,
  UserRole,
  CategoryType,
  TaskStatus,
  BidStatus,
  KycStatus,
  ConnectStatus,
} from './generated';
import { PrismaPg } from '@prisma/adapter-pg';
import { createId } from '@paralleldrive/cuid2';
import { faker } from '@faker-js/faker';

// Prisma 7 — PrismaClient takes a driver adapter instead of relying on
// the datasource URL. The migrate engine uses prisma.config.ts; this
// adapter is for runtime queries inside the seed.
const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL,
});
const prisma = new PrismaClient({ adapter });

// ─── DELIBERATE TYPE ERROR — TEMPORARY ─────────────────────────────────
// This line is here to test the CI gate. It is a string assigned to a
// `number` typed variable, which tsc must catch on `pnpm --filter
// @jobbees/prisma run typecheck`. If CI passes with this line in place,
// the typecheck script is not actually scanning seed.ts.
// REMOVE THIS BLOCK AFTER VERIFYING CI BLOCKS THE MERGE.
const _ciGateTest: number = 'this should fail typecheck';
// ───────────────────────────────────────────────────────────────────────

async function main() {
  console.log('🌱 Seeding JOBBees development database...');

  // -----------------------------
  // Country
  // -----------------------------
  await prisma.country.upsert({
    where: { code: 'AU' },
    update: {},
    create: {
      code: 'AU',
      name: 'Australia',
      currencyCode: 'AUD',
      defaultLocale: 'en-AU',
      taxModel: 'AU_GST_RCTI_ATO',
      phonePrefix: '+61',
      isActive: true,
    },
  });
  console.log('  ✓ Country: AU');

  // -----------------------------
  // Categories (transactional)
  // -----------------------------
  const categories = [
    { slug: 'cleaning', name: 'Cleaning' },
    { slug: 'moving', name: 'Moving & Delivery' },
    { slug: 'handyman', name: 'Handyman' },
    { slug: 'gardening', name: 'Gardening & Yard Work' },
    { slug: 'assembly', name: 'Assembly' },
    { slug: 'errands', name: 'Errands & Tasks' },
    { slug: 'tech-help', name: 'Tech Help' },
    { slug: 'pet-care', name: 'Pet Care' },
  ];

  for (const cat of categories) {
    await prisma.category.upsert({
      where: { slug: cat.slug },
      update: {},
      create: {
        id: createId(),
        slug: cat.slug,
        name: cat.name,
        type: CategoryType.TRANSACTIONAL,
        commissionRateBp: 1500, // 15.00%
        isActive: true,
      },
    });
  }
  console.log(`  ✓ Categories: ${categories.length}`);

  // -----------------------------
  // Users
  // -----------------------------
  await prisma.user.upsert({
    where: { email: 'admin@jobbees.local' },
    update: {},
    create: {
      id: createId(),
      email: 'admin@jobbees.local',
      firstName: 'Super',
      lastName: 'Admin',
      role: UserRole.SUPER_ADMIN,
      emailVerified: true,
      countryCode: 'AU',
      kycStatus: KycStatus.APPROVED,
    },
  });
  console.log(`  ✓ Super admin: admin@jobbees.local`);

  const posters: Array<{ id: string; email: string }> = [];
  for (let i = 0; i < 5; i++) {
    const email = `poster${i + 1}@jobbees.local`;
    const u = await prisma.user.upsert({
      where: { email },
      update: {},
      create: {
        id: createId(),
        email,
        phone: `+61400${faker.string.numeric(6)}`,
        firstName: faker.person.firstName(),
        lastName: faker.person.lastName(),
        role: UserRole.POSTER,
        emailVerified: true,
        countryCode: 'AU',
        kycStatus: KycStatus.APPROVED,
        defaultAddress: `${faker.location.streetAddress()}, ${faker.location.city()} NSW`,
      },
    });
    posters.push({ id: u.id, email: u.email });
  }
  console.log(`  ✓ Posters: ${posters.length}`);

  const taskers: Array<{ id: string; email: string }> = [];
  for (let i = 0; i < 10; i++) {
    const email = `tasker${i + 1}@jobbees.local`;
    const u = await prisma.user.upsert({
      where: { email },
      update: {},
      create: {
        id: createId(),
        email,
        phone: `+61400${faker.string.numeric(6)}`,
        firstName: faker.person.firstName(),
        lastName: faker.person.lastName(),
        role: UserRole.TASKER,
        emailVerified: true,
        phoneVerified: true,
        countryCode: 'AU',
        kycStatus: KycStatus.APPROVED,
        connectStatus: ConnectStatus.COMPLETE,
        bio: faker.lorem.paragraph(),
        hourlyRateCents: faker.number.int({ min: 3500, max: 9500 }),
      },
    });
    taskers.push({ id: u.id, email: u.email });
  }
  console.log(`  ✓ Taskers: ${taskers.length}`);

  // -----------------------------
  // Tasks
  // -----------------------------
  const allCategories = await prisma.category.findMany();
  for (let i = 0; i < 20; i++) {
    const poster = faker.helpers.arrayElement(posters);
    const category = faker.helpers.arrayElement(allCategories);
    await prisma.task.create({
      data: {
        id: createId(),
        posterId: poster.id,
        categoryId: category.id,
        title: faker.lorem.sentence({ min: 3, max: 7 }),
        description: faker.lorem.paragraphs(2),
        countryCode: 'AU',
        transactionType: category.type,
        budgetCents: faker.number.int({ min: 3000, max: 30000 }),
        addressLine: faker.location.streetAddress(),
        suburb: faker.location.city(),
        postcode: faker.location.zipCode('####'),
        latitude: parseFloat(faker.location.latitude({ min: -34, max: -33 }).toFixed(6)),
        longitude: parseFloat(faker.location.longitude({ min: 150, max: 152 }).toFixed(6)),
        scheduledAt: faker.date.soon({ days: 7 }),
        durationHours: faker.number.int({ min: 1, max: 8 }),
        status: TaskStatus.BIDDING,
        publishedAt: new Date(),
      },
    });
  }
  console.log(`  ✓ Tasks: 20`);

  // -----------------------------
  // Bids
  // -----------------------------
  const tasks = await prisma.task.findMany({ where: { status: TaskStatus.BIDDING } });
  let bidCount = 0;
  for (const task of tasks) {
    const numBids = faker.number.int({ min: 0, max: 4 });
    const biddersForThisTask = faker.helpers.arrayElements(taskers, numBids);
    for (const tasker of biddersForThisTask) {
      await prisma.bid.create({
        data: {
          id: createId(),
          taskId: task.id,
          taskerId: tasker.id,
          amountCents: faker.number.int({
            min: Math.floor(task.budgetCents * 0.8),
            max: Math.ceil(task.budgetCents * 1.2),
          }),
          message: faker.lorem.sentence(),
          status: BidStatus.ACTIVE,
          expiresAt: faker.date.soon({ days: 2 }),
        },
      });
      bidCount++;
    }
  }
  console.log(`  ✓ Bids: ${bidCount}`);

  console.log('🌱 Seed complete.');
  console.log('');
  console.log('Test accounts:');
  console.log('  Super admin: admin@jobbees.local');
  console.log('  Posters:     poster1@jobbees.local ... poster5@jobbees.local');
  console.log('  Taskers:     tasker1@jobbees.local ... tasker10@jobbees.local');
  console.log('  (All passwords: set via your auth flow — none stored in seed)');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
