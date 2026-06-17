import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { PrismaService } from '../prisma/prisma.service';

interface HealthResponse {
  status: 'ok';
  db: 'up' | 'down';
  timestamp: string;
}

/**
 * Liveness + DB-readiness probe. Public (no guard) — used by load balancers
 * and the Sprint 1 foundation demo.
 */
@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @ApiOperation({ summary: 'Liveness + database readiness probe' })
  async check(): Promise<HealthResponse> {
    let db: 'up' | 'down' = 'up';
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      db = 'down';
    }
    return { status: 'ok', db, timestamp: new Date().toISOString() };
  }
}
