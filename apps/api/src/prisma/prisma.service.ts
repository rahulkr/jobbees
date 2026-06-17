import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@jobbees/prisma';

/**
 * Application-wide Prisma client.
 *
 * Prisma 7 pattern: the client is constructed with a `PrismaPg` driver adapter
 * built from `DATABASE_URL` (the legacy `datasource { url = env(...) }` line no
 * longer exists). Connects on module init, disconnects on shutdown.
 *
 * Raw SQL is reserved for pgvector similarity + analytical queries only
 * (CLAUDE.md); everything else uses the typed client.
 */
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);

  constructor(config: ConfigService) {
    const adapter = new PrismaPg({
      connectionString: config.getOrThrow<string>('DATABASE_URL'),
    });
    super({ adapter });
  }

  async onModuleInit(): Promise<void> {
    await this.$connect();
    this.logger.log('Prisma connected');
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
