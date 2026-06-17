import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { UserRole } from '@jobbees/prisma';
import * as argon2 from 'argon2';
import * as cookieParser from 'cookie-parser';
import * as request from 'supertest';
import { AppModule } from './../src/app.module';
import { MailService } from './../src/modules/auth/mail/mail.service';
import { GoogleVerifier } from './../src/modules/auth/oauth/google.verifier';
import { TokenService } from './../src/modules/auth/token.service';
import { PrismaService } from './../src/prisma/prisma.service';

// Captures the tokens the mock mailer would have sent (never in API responses).
const mailTokens = {
  verify: new Map<string, string>(),
  reset: new Map<string, string>(),
};

/**
 * Route-level auth flow (security-review skill §L1). Requires local Postgres +
 * Redis (pnpm docker:up). Not run by `pnpm test` (unit only) — run via
 * `pnpm --filter @jobbees/api test:e2e`.
 */
describe('Auth (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  // Unique per run so the 24h idempotency cache (shared Redis) never replays a
  // previous run's response — keeps the suite deterministic on a persistent DB.
  const run = Date.now();
  const email = `e2e-auth-${run}@example.com`;
  const oauthEmail = `e2e-oauth-${run}@example.com`;
  const adminEmail = `e2e-admin-${run}@example.com`;
  const password = 'a-strong-passphrase';
  const idem = (key: string) => ['Idempotency-Key', `${key}-${run}`] as const;

  let access = '';
  let refresh = '';
  let adminToken = '';

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      // Stub Google verification — exercise the OAuth route without a real token.
      .overrideProvider(GoogleVerifier)
      .useValue({
        verify: () =>
          Promise.resolve({
            provider: 'google',
            providerId: 'g-e2e',
            email: oauthEmail,
            emailVerified: true,
            firstName: 'O',
            lastName: 'Auth',
          }),
      })
      // Capture tokens the mailer would send so the e2e can complete the flows.
      .overrideProvider(MailService)
      .useValue({
        sendEmailVerification: (to: string, token: string) => {
          mailTokens.verify.set(to, token);
          return Promise.resolve();
        },
        sendPasswordReset: (to: string, token: string) => {
          mailTokens.reset.set(to, token);
          return Promise.resolve();
        },
      })
      .compile();
    app = moduleRef.createNestApplication();
    app.use(cookieParser());
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

    // Seed an ADMIN directly (signup can't create admins) + mint its token
    // via TokenService — avoids spending a login against the rate limit.
    await prisma.user.deleteMany({ where: { email: adminEmail } });
    const admin = await prisma.user.create({
      data: {
        id: `admin-e2e-${run}`,
        email: adminEmail,
        firstName: 'Ad',
        lastName: 'Min',
        role: UserRole.ADMIN,
        passwordHash: await argon2.hash('admin-passphrase', {
          type: argon2.argon2id,
        }),
      },
    });
    adminToken = (await app.get(TokenService).issueForUser(admin.id, UserRole.ADMIN)).accessToken;
  });

  afterAll(async () => {
    await prisma.user.deleteMany({
      where: { email: { in: [email, oauthEmail, adminEmail] } },
    });
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

    refresh = rotated.body.refreshToken; // keep the current valid token
  });

  it('reauth: correct password grants a window, wrong password → 401', async () => {
    const ok = await request(server())
      .post('/auth/reauth')
      .set('Authorization', `Bearer ${access}`)
      .set(...idem('e2e-reauth-ok'))
      .send({ password })
      .expect(200);
    expect(ok.body.validForSeconds).toBeGreaterThan(0);

    await request(server())
      .post('/auth/reauth')
      .set('Authorization', `Bearer ${access}`)
      .set(...idem('e2e-reauth-bad'))
      .send({ password: 'not-the-password' })
      .expect(401);
  });

  it('logout-all revokes every session (refresh then 401)', async () => {
    await request(server())
      .post('/auth/logout-all')
      .set('Authorization', `Bearer ${access}`)
      .set(...idem('e2e-logoutall'))
      .expect(204);

    await request(server())
      .post('/auth/refresh')
      .set(...idem('e2e-logoutall-refresh'))
      .send({ refreshToken: refresh })
      .expect(401);
  });

  it('client is blocked from OTP routes (403 — @Roles TASKER)', () =>
    request(server())
      .post('/auth/otp/send')
      .set('Authorization', `Bearer ${access}`)
      .set(...idem('e2e-client-otp'))
      .send({ phone: '+61400000001' })
      .expect(403));

  it('tasker can send + verify a phone OTP', async () => {
    const taskerEmail = `e2e-tasker-${Date.now()}@example.com`;
    const signup = await request(server())
      .post('/auth/signup')
      .set(...idem('e2e-tasker-signup'))
      .send({
        email: taskerEmail,
        password,
        firstName: 'E2E',
        lastName: 'Tasker',
        role: 'TASKER',
      })
      .expect(201);
    const taskerToken = signup.body.accessToken;

    await request(server())
      .post('/auth/otp/send')
      .set('Authorization', `Bearer ${taskerToken}`)
      .set(...idem('e2e-tasker-otp-send'))
      .send({ phone: '+61400000099' })
      .expect(200);

    const verified = await request(server())
      .post('/auth/otp/verify')
      .set('Authorization', `Bearer ${taskerToken}`)
      .set(...idem('e2e-tasker-otp-verify'))
      .send({ phone: '+61400000099', code: '000000' })
      .expect(200);
    expect(verified.body.phoneVerified).toBe(true);

    await prisma.user.deleteMany({ where: { email: taskerEmail } });
  });

  it('google OAuth signs up a new user + issues tokens', async () => {
    const res = await request(server())
      .post('/auth/oauth/google')
      .set(...idem('e2e-oauth-google'))
      .send({ idToken: 'stub-token-verified-by-override' })
      .expect(200);
    expect(res.body.accessToken).toEqual(expect.any(String));

    const me = await request(server())
      .get('/auth/me')
      .set('Authorization', `Bearer ${res.body.accessToken}`)
      .expect(200);
    expect(me.body.email).toBe(oauthEmail);
  });

  it('rejects an unsupported OAuth provider (400)', () =>
    request(server())
      .post('/auth/oauth/facebook')
      .set(...idem('e2e-oauth-bad'))
      .send({ idToken: 'x' })
      .expect(400));

  it('verifies email with the emailed token', async () => {
    const token = mailTokens.verify.get(email);
    expect(token).toBeDefined();
    await request(server())
      .post('/auth/email/verify')
      .set(...idem('e2e-email-verify'))
      .send({ token })
      .expect(200);

    const me = await request(server())
      .get('/auth/me')
      .set('Authorization', `Bearer ${access}`)
      .expect(200);
    expect(me.body.emailVerified).toBe(true);
  });

  it('forgot + reset password, then login with the new password', async () => {
    const resetEmail = `e2e-reset-${run}@example.com`;
    const newPassword = 'a-brand-new-passphrase';
    await request(server())
      .post('/auth/signup')
      .set(...idem('e2e-reset-signup'))
      .send({ email: resetEmail, password, firstName: 'R', lastName: 'Set' })
      .expect(201);

    await request(server())
      .post('/auth/password/forgot')
      .set(...idem('e2e-reset-forgot'))
      .send({ email: resetEmail })
      .expect(200);
    const token = mailTokens.reset.get(resetEmail);
    expect(token).toBeDefined();

    await request(server())
      .post('/auth/password/reset')
      .set(...idem('e2e-reset-do'))
      .send({ token, newPassword })
      .expect(200);

    // Old password no longer works; new one does.
    await request(server())
      .post('/auth/login')
      .set(...idem('e2e-reset-oldpw'))
      .send({ email: resetEmail, password })
      .expect(401);
    await request(server())
      .post('/auth/login')
      .set(...idem('e2e-reset-newpw'))
      .send({ email: resetEmail, password: newPassword })
      .expect(200);

    await prisma.user.deleteMany({ where: { email: resetEmail } });
  });

  it('non-admin cannot call admin routes (403)', () =>
    request(server())
      .post(`/admin/users/some-id/suspend`)
      .set('Authorization', `Bearer ${access}`)
      .set(...idem('e2e-admin-rbac'))
      .send({})
      .expect(403));

  it('admin suspends a user (login blocked), then reinstates', async () => {
    const targetEmail = `e2e-target-${run}@example.com`;
    const target = await prisma.user.create({
      data: {
        id: `target-e2e-${run}`,
        email: targetEmail,
        firstName: 'Tar',
        lastName: 'Get',
        role: UserRole.CLIENT,
        passwordHash: await argon2.hash('target-passphrase', {
          type: argon2.argon2id,
        }),
      },
    });

    await request(server())
      .post(`/admin/users/${target.id}/suspend`)
      .set('Authorization', `Bearer ${adminToken}`)
      .set(...idem('e2e-suspend'))
      .send({ reason: 'e2e test' })
      .expect(204);

    // Suspended → login blocked even with the correct password.
    await request(server())
      .post('/auth/login')
      .set(...idem('e2e-suspended-login'))
      .send({ email: targetEmail, password: 'target-passphrase' })
      .expect(403);

    await request(server())
      .post(`/admin/users/${target.id}/reinstate`)
      .set('Authorization', `Bearer ${adminToken}`)
      .set(...idem('e2e-reinstate'))
      .expect(204);

    const after = await prisma.user.findFirst({ where: { id: target.id } });
    expect(after?.suspendedAt).toBeNull();

    await prisma.user.deleteMany({ where: { email: targetEmail } });
  });

  it('AuditLog is append-only (update + delete blocked at the DB)', async () => {
    const id = `al-e2e-${run}`;
    await prisma.auditLog.create({
      data: { id, action: 'test.write', resourceType: 'User', resourceId: 'u-test' },
    });
    await expect(
      prisma.auditLog.update({ where: { id }, data: { action: 'tampered' } }),
    ).rejects.toThrow();
    await expect(prisma.auditLog.delete({ where: { id } })).rejects.toThrow();
    // The row is intentionally left behind — it cannot be deleted (that's the point).
  });

  it('web surface: cookie session, CSRF enforcement, refresh + logout', async () => {
    const agent = request.agent(server());

    // Web login → HttpOnly cookies + a csrfToken in the body (no raw tokens).
    const login = await agent
      .post('/auth/login')
      .set('X-Surface', 'web')
      .set(...idem('e2e-web-login'))
      .send({ email, password })
      .expect(200);
    expect(login.body.csrfToken).toEqual(expect.any(String));
    expect(login.body).not.toHaveProperty('accessToken');
    expect((login.headers['set-cookie'] as unknown as string[]).join(';')).toMatch(/jb_access=/);
    let csrf = login.body.csrfToken as string;

    // /me authenticates via the jb_access cookie (agent resends it).
    const me = await agent.get('/auth/me').set('X-Surface', 'web').expect(200);
    expect(me.body.email).toBe(email);

    // A cookie-auth mutating request without the CSRF header is rejected.
    await agent
      .post('/auth/logout-all')
      .set('X-Surface', 'web')
      .set(...idem('e2e-web-nocsrf'))
      .expect(403);

    // Refresh via cookie + CSRF rotates the session (new csrfToken issued).
    const refreshed = await agent
      .post('/auth/refresh')
      .set('X-Surface', 'web')
      .set('X-XSRF-TOKEN', csrf)
      .set(...idem('e2e-web-refresh'))
      .expect(200);
    csrf = refreshed.body.csrfToken as string;

    // Logout clears the cookies.
    const out = await agent
      .post('/auth/logout')
      .set('X-Surface', 'web')
      .set('X-XSRF-TOKEN', csrf)
      .set(...idem('e2e-web-logout'))
      .expect(204);
    expect((out.headers['set-cookie'] as unknown as string[]).join(';')).toMatch(/jb_access=;/);
  });
});
