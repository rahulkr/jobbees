import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { LoggerModule } from 'nestjs-pino';
import { CommonModule } from './common/common.module';
import { buildLoggerConfig } from './common/logger/logger.config';
import { validateEnv } from './config/env.validation';
import { HealthController } from './health/health.controller';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      validate: validateEnv,
      // Local dev reads from the API workspace first, then the repo-root env
      // (where prisma's DATABASE_URL also lives). Prod injects real env vars.
      envFilePath: ['.env.local', '.env', '../../.env.local', '../../.env'],
    }),
    LoggerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        buildLoggerConfig(config.get<string>('NODE_ENV', 'development')),
    }),
    PrismaModule,
    CommonModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
