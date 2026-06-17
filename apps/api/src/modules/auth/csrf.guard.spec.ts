import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { CsrfGuard } from './csrf.guard';

function mockContext(
  method: string,
  cookies: Record<string, string | undefined>,
  xsrfHeader?: string,
): ExecutionContext {
  const request = {
    method,
    cookies,
    header: (h: string) => (h.toLowerCase() === 'x-xsrf-token' ? xsrfHeader : undefined),
  };
  return {
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext;
}

describe('CsrfGuard', () => {
  const guard = new CsrfGuard();

  it('allows safe methods', () => {
    expect(guard.canActivate(mockContext('GET', {}))).toBe(true);
  });

  it('allows non-cookie (Bearer) mutating requests', () => {
    expect(guard.canActivate(mockContext('POST', {}))).toBe(true);
  });

  it('allows cookie-auth mutating requests with a matching token', () => {
    expect(
      guard.canActivate(mockContext('POST', { jb_access: 'a', 'XSRF-TOKEN': 'tok' }, 'tok')),
    ).toBe(true);
  });

  it('403 when cookie-auth mutating without the header', () => {
    expect(() =>
      guard.canActivate(mockContext('POST', { jb_access: 'a', 'XSRF-TOKEN': 'tok' })),
    ).toThrow(ForbiddenException);
  });

  it('403 on token mismatch', () => {
    expect(() =>
      guard.canActivate(mockContext('POST', { jb_access: 'a', 'XSRF-TOKEN': 'tok' }, 'WRONG')),
    ).toThrow(ForbiddenException);
  });
});
