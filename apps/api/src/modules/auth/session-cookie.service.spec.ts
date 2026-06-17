import { ConfigService } from '@nestjs/config';
import type { Request, Response } from 'express';
import {
  ACCESS_COOKIE,
  CSRF_COOKIE,
  REFRESH_COOKIE,
  SessionCookieService,
} from './session-cookie.service';

function build(nodeEnv = 'development') {
  const config = {
    get: jest.fn((key: string, def?: unknown) => {
      if (key === 'NODE_ENV') return nodeEnv;
      if (key === 'JWT_ACCESS_TTL_SECONDS') return 900;
      if (key === 'JWT_REFRESH_TTL_DAYS') return 30;
      return def;
    }),
  };
  return new SessionCookieService(config as unknown as ConfigService);
}

const reqWith = (surface?: string) =>
  ({
    header: (h: string) => (h.toLowerCase() === 'x-surface' ? surface : undefined),
  }) as unknown as Request;

function resMock() {
  return { cookie: jest.fn(), clearCookie: jest.fn() };
}

const PAIR = { accessToken: 'a', refreshToken: 'r' };

describe('SessionCookieService', () => {
  it('mobile (no X-Surface) returns the token pair, sets no cookies', () => {
    const svc = build();
    const res = resMock();
    const out = svc.deliver(reqWith(undefined), res as unknown as Response, PAIR);
    expect(out).toEqual(PAIR);
    expect(res.cookie).not.toHaveBeenCalled();
  });

  it('web sets 3 cookies + returns only a csrfToken', () => {
    const svc = build();
    const res = resMock();
    const out = svc.deliver(reqWith('web'), res as unknown as Response, PAIR);
    expect(out).toEqual({ csrfToken: expect.any(String) });
    expect(out).not.toHaveProperty('accessToken');
    const names = res.cookie.mock.calls.map((c) => c[0]);
    expect(names).toEqual(expect.arrayContaining([ACCESS_COOKIE, REFRESH_COOKIE, CSRF_COOKIE]));
  });

  it('clear removes all session cookies', () => {
    const svc = build();
    const res = resMock();
    svc.clear(res as unknown as Response);
    expect(res.clearCookie).toHaveBeenCalledTimes(3);
  });
});
