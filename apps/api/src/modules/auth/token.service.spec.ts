import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '@jobbees/prisma';
import { PrismaService } from '../../prisma/prisma.service';
import { TokenService } from './token.service';

function build() {
  const jwt = {
    signAsync: jest.fn().mockResolvedValue('access.jwt'),
    verifyAsync: jest.fn(),
  };
  const config = {
    getOrThrow: jest.fn().mockReturnValue('a-test-secret-at-least-32-chars-long'),
    get: jest.fn((_key: string, def: unknown) => def),
  };
  const prisma = {
    refreshToken: {
      create: jest.fn().mockResolvedValue({}),
      findUnique: jest.fn(),
      update: jest.fn().mockResolvedValue({}),
      updateMany: jest.fn().mockResolvedValue({ count: 1 }),
    },
    user: { findFirst: jest.fn() },
    $transaction: jest.fn().mockResolvedValue([]),
  };
  const service = new TokenService(
    jwt as unknown as JwtService,
    config as unknown as ConfigService,
    prisma as unknown as PrismaService,
  );
  return { service, jwt, prisma };
}

const future = () => new Date(Date.now() + 60 * 60 * 1000);
const past = () => new Date(Date.now() - 1000);

describe('TokenService', () => {
  it('issues an access JWT and persists a refresh token', async () => {
    const { service, prisma } = build();
    const pair = await service.issueForUser('u1', UserRole.CLIENT);
    expect(pair.accessToken).toBe('access.jwt');
    expect(typeof pair.refreshToken).toBe('string');
    expect(prisma.refreshToken.create).toHaveBeenCalledTimes(1);
  });

  it('rotates: revokes old + issues new pair', async () => {
    const { service, prisma } = build();
    prisma.refreshToken.findUnique.mockResolvedValue({
      id: 't1',
      userId: 'u1',
      revokedAt: null,
      expiresAt: future(),
    });
    prisma.user.findFirst.mockResolvedValue({ id: 'u1', role: UserRole.CLIENT });
    const pair = await service.rotate('raw-token');
    expect(pair.accessToken).toBe('access.jwt');
    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
  });

  it('detects reuse of a revoked token and burns the session set', async () => {
    const { service, prisma } = build();
    prisma.refreshToken.findUnique.mockResolvedValue({
      id: 't1',
      userId: 'u1',
      revokedAt: new Date(),
      expiresAt: future(),
    });
    await expect(service.rotate('raw-token')).rejects.toBeInstanceOf(UnauthorizedException);
    expect(prisma.refreshToken.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { userId: 'u1', revokedAt: null } }),
    );
  });

  it('rejects an unknown refresh token', async () => {
    const { service, prisma } = build();
    prisma.refreshToken.findUnique.mockResolvedValue(null);
    await expect(service.rotate('nope')).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('rejects an expired refresh token', async () => {
    const { service, prisma } = build();
    prisma.refreshToken.findUnique.mockResolvedValue({
      id: 't1',
      userId: 'u1',
      revokedAt: null,
      expiresAt: past(),
    });
    await expect(service.rotate('raw-token')).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
