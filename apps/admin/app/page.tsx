'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { ADMIN_ROLES, logout, me, type AdminUser } from '@/lib/api';

export default function DashboardPage() {
  const router = useRouter();
  const [user, setUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    void me().then((u) => {
      if (!active) return;
      // No session (or expired → 401) or a non-admin role → back to login.
      if (!u || !ADMIN_ROLES.includes(u.role)) {
        router.replace('/login');
        return;
      }
      setUser(u);
      setLoading(false);
    });
    return () => {
      active = false;
    };
  }, [router]);

  async function onLogout() {
    await logout();
    router.replace('/login');
  }

  if (loading || !user) {
    return (
      <main className="flex min-h-screen items-center justify-center text-sm text-zinc-500">
        Loading…
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-zinc-50 p-8 dark:bg-zinc-950">
      <header className="mx-auto flex max-w-4xl items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-zinc-900 dark:text-zinc-50">JOBBees Admin</h1>
          <p className="text-sm text-zinc-500">
            {user.firstName} {user.lastName} · {user.email} · {user.role}
          </p>
        </div>
        <button
          onClick={onLogout}
          className="rounded-lg border border-zinc-300 px-3 py-1.5 text-sm font-medium text-zinc-700 hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-200"
        >
          Log out
        </button>
      </header>

      <section className="mx-auto mt-10 max-w-4xl rounded-2xl bg-white p-8 text-sm text-zinc-500 shadow-sm dark:bg-zinc-900">
        The admin console is just the door for now — the full operations UI (KYC, disputes,
        payments, reports) arrives in Sprint 9.
      </section>
    </main>
  );
}
