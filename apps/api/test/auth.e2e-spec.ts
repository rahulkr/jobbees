import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import * as request from 'supertest';
import { AppModule } from './../src/app.module';
import { PrismaService } from './../src/prisma/prisma.service';

/**
 * Route-level auth flow (security-review skill §L1). Requires local Postgres +
 * Redis (pnpm docker:up). Not run by `pnpm test` (unit only) — run via
 * `pnpm --filter @jobbees/api test:e2e`.
 */
describe('Auth (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const email = `e2e-auth-${Date.now()}@example.com`;
  const password = 'a-strong-passphrase';
  const idem = (key: string) => ['Idempotency-Key', key] as const;

  let access = '';
  let refresh = '';

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();

    prisma = app.get(PrismaService);
    // Signup needs the AU country FK to exist.
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
    await prisma.user.deleteMany({ where: { email } });
  });

  afterAll(async () => {
    await prisma.user.deleteMany({ where: { email } });
    await app.close();
  });

  const server = () => app.getHttpServer();

  it('signup → 201 + token pair', async () => {
    const res = await request(server())
      .post('/auth/signup')
      .set(...idem('e2e-signup'))
      .send({ email, password, firstName: 'E2E', lastName: 'User' })
      .expect(201);
    expect(res.body.accessToken).toEqual(expect.any(String));
    expect(res.body.refreshToken).toEqual(expect.any(String));
    access = res.body.accessToken;
    refresh = res.body.refreshToken;
  });

  it('signup without Idempotency-Key → 400', () =>
    request(server())
      .post('/auth/signup')
      .send({ email: `other-${email}`, password, firstName: 'A', lastName: 'B' })
      .expect(400));

  it('signup rejects an unknown role (no privilege escalation)', () =>
    request(server())
      .post('/auth/signup')
      .set(...idem('e2e-admin-attempt'))
      .send({
        email: `admin-${email}`,
        password,
        firstName: 'A',
        lastName: 'B',
        role: 'ADMIN',
      })
      .expect(400));

  it('GET /me with token → 200, no passwordHash', async () => {
    const res = await request(server())
      .get('/auth/me')
      .set('Authorization', `Bearer ${access}`)
      .expect(200);
    expect(res.body.email).toBe(email);
    expect(res.body).not.toHaveProperty('passwordHash');
  });

  it('GET /me without token → 401', () => request(server()).get('/auth/me').expect(401));

  it('login with the wrong password → 401', () =>
    request(server())
      .post('/auth/login')
      .set(...idem('e2e-badlogin'))
      .send({ email, password: 'wrong-password' })
      .expect(401));

  it('refresh rotates; reusing the old token → 401', async () => {
    const rotated = await request(server())
      .post('/auth/refresh')
      .set(...idem('e2e-refresh-1'))
      .send({ refreshToken: refresh })
      .expect(200);
    expect(rotated.body.refreshToken).not.toBe(refresh);

    await request(server())
      .post('/auth/refresh')
      .set(...idem('e2e-refresh-reuse'))
      .send({ refreshToken: refresh })
      .expect(401);
  });
});
