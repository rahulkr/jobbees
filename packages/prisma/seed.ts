/**
 * JOBBees — Database seed
 *
 * Run with: pnpm db:seed
 *
 * Creates a usable local development environment:
 * - 1 super admin user
 * - 5 test clients, 10 test taskers (KYC stub'd to APPROVED)
 * - Country (AU only at MVP)
 * - Categories (transactional, with parent/child hierarchy)
 * - 20 sample jobs across categories
 * - A few sample offers
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
  JobStatus,
  OfferStatus,
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
    { slug: 'errands', name: 'Errands & Jobs' },
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

  const clients: Array<{ id: string; email: string }> = [];
  for (let i = 0; i < 5; i++) {
    const email = `client${i + 1}@jobbees.local`;
    const u = await prisma.user.upsert({
      where: { email },
      update: {},
      create: {
        id: createId(),
        email,
        phone: `+61400${faker.string.numeric(6)}`,
        firstName: faker.person.firstName(),
        lastName: faker.person.lastName(),
        role: UserRole.CLIENT,
        emailVerified: true,
        countryCode: 'AU',
        kycStatus: KycStatus.APPROVED,
        defaultAddress: `${faker.location.streetAddress()}, ${faker.location.city()} NSW`,
      },
    });
    clients.push({ id: u.id, email: u.email });
  }
  console.log(`  ✓ Clients: ${clients.length}`);

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
  // Jobs
  // -----------------------------
  const allCategories = await prisma.category.findMany();
  for (let i = 0; i < 20; i++) {
    const client = faker.helpers.arrayElement(clients);
    const category = faker.helpers.arrayElement(allCategories);
    await prisma.job.create({
      data: {
        id: createId(),
        clientId: client.id,
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
        status: JobStatus.OFFERING,
        publishedAt: new Date(),
      },
    });
  }
  console.log(`  ✓ Jobs: 20`);

  // -----------------------------
  // Offers
  // -----------------------------
  const jobs = await prisma.job.findMany({ where: { status: JobStatus.OFFERING } });
  let offerCount = 0;
  for (const job of jobs) {
    const numOffers = faker.number.int({ min: 0, max: 4 });
    const offerersForThisJob = faker.helpers.arrayElements(taskers, numOffers);
    for (const tasker of offerersForThisJob) {
      await prisma.offer.create({
        data: {
          id: createId(),
          jobId: job.id,
          taskerId: tasker.id,
          amountCents: faker.number.int({
            min: Math.floor(job.budgetCents * 0.8),
            max: Math.ceil(job.budgetCents * 1.2),
          }),
          message: faker.lorem.sentence(),
          status: OfferStatus.ACTIVE,
          expiresAt: faker.date.soon({ days: 2 }),
        },
      });
      offerCount++;
    }
  }
  console.log(`  ✓ Offers: ${offerCount}`);

  console.log('🌱 Seed complete.');
  console.log('');
  console.log('Test accounts:');
  console.log('  Super admin: admin@jobbees.local');
  console.log('  Clients:     client1@jobbees.local ... client5@jobbees.local');
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
