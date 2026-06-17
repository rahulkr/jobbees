// Admin → JOBBees API client (web surface, ADR 006 cookie + CSRF).
//
// The session lives in HttpOnly cookies set by the API (sent automatically with
// `credentials: 'include'`). The double-submit CSRF token is returned in the
// login response body and echoed on mutating requests.

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';
const CSRF_STORAGE_KEY = 'jb_admin_csrf';

export interface AdminUser {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: string;
}

type Method = 'GET' | 'POST';

async function call(
  path: string,
  method: Method,
  opts: { body?: unknown; csrf?: boolean } = {},
): Promise<Response> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'X-Surface': 'web',
  };
  if (method !== 'GET') {
    headers['Idempotency-Key'] = crypto.randomUUID();
  }
  if (opts.csrf) {
    headers['X-XSRF-TOKEN'] = sessionStorage.getItem(CSRF_STORAGE_KEY) ?? '';
  }
  return fetch(`${API_URL}${path}`, {
    method,
    credentials: 'include',
    headers,
    body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
  });
}

export async function login(email: string, password: string): Promise<void> {
  const res = await call('/auth/login', 'POST', { body: { email, password } });
  if (!res.ok) {
    throw new Error('Invalid email or password');
  }
  const data = (await res.json()) as { csrfToken?: string };
  if (data.csrfToken) {
    sessionStorage.setItem(CSRF_STORAGE_KEY, data.csrfToken);
  }
}

export async function me(): Promise<AdminUser | null> {
  const res = await call('/auth/me', 'GET');
  if (!res.ok) {
    return null;
  }
  return (await res.json()) as AdminUser;
}

export async function logout(): Promise<void> {
  await call('/auth/logout', 'POST', { body: {}, csrf: true });
  sessionStorage.removeItem(CSRF_STORAGE_KEY);
}

export const ADMIN_ROLES = ['ADMIN', 'SUPER_ADMIN'];
