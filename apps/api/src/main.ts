import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import * as cookieParser from 'cookie-parser';
import { Logger } from 'nestjs-pino';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });

  // Route Nest's logs through pino.
  app.useLogger(app.get(Logger));

  // Parse cookies (web/admin session auth — ADR 006).
  app.use(cookieParser());

  const config = app.get(ConfigService);

  // CORS for credentialed browser clients (admin / web). Same-site subdomains
  // in prod; localhost:3001 (admin dev) by default.
  const corsOrigins = config
    .get<string>('CORS_ORIGINS', '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
  app.enableCors({
    origin: corsOrigins.length > 0 ? corsOrigins : ['http://localhost:3001'],
    credentials: true,
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Surface',
      'X-XSRF-TOKEN',
      'Idempotency-Key',
    ],
  });

  // Reject unknown / malformed payloads everywhere; transform to DTO instances.
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // One consistent error envelope across every endpoint.
  app.useGlobalFilters(new AllExceptionsFilter());

  // Clean Prisma disconnect on SIGTERM/SIGINT.
  app.enableShutdownHooks();

  const swaggerConfig = new DocumentBuilder()
    .setTitle('JOBBees API')
    .setDescription('JOBBees backend — auth foundation (Sprint 1)')
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();
  SwaggerModule.setup('api/docs', app, SwaggerModule.createDocument(app, swaggerConfig));

  const port = config.get<number>('PORT', 3000);
  await app.listen(port);
}

void bootstrap();
