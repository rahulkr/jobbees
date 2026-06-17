import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { AppModule } from '../src/app.module';

/**
 * Regenerates apps/api/openapi.json — the committed API contract, importable
 * directly into Postman / Insomnia / Bruno (File → Import).
 *
 * Runs in `preview` mode so providers aren't instantiated (no Prisma/Redis
 * connection needed) — pure route + schema introspection.
 *
 * Usage: pnpm --filter @jobbees/api export:openapi
 */
async function main(): Promise<void> {
  const app = await NestFactory.create(AppModule, {
    preview: true,
    logger: false,
  });

  const config = new DocumentBuilder()
    .setTitle('JOBBees API')
    .setDescription('JOBBees backend — auth foundation (Sprint 1)')
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  const outPath = join(__dirname, '..', 'openapi.json');
  writeFileSync(outPath, `${JSON.stringify(document, null, 2)}\n`);
  await app.close();

  process.stdout.write(`OpenAPI spec written to ${outPath}\n`);
}

void main();
