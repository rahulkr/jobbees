import type { Params } from 'nestjs-pino';

/**
 * pino logger config (structured JSON in prod, pretty in dev).
 *
 * `redact` strips credentials + PII from logs at the transport layer — a
 * belt-and-braces backstop on top of "never log PII" (CLAUDE.md). Add new
 * sensitive request/response paths here as endpoints land.
 */
export function buildLoggerConfig(nodeEnv: string): Params {
  const isProd = nodeEnv === 'production';

  return {
    pinoHttp: {
      level: isProd ? 'info' : 'debug',
      transport: isProd ? undefined : { target: 'pino-pretty', options: { singleLine: true } },
      redact: {
        paths: [
          'req.headers.authorization',
          'req.headers.cookie',
          'res.headers["set-cookie"]',
          'req.body.password',
          'req.body.passwordHash',
          'req.body.token',
          'req.body.refreshToken',
          'req.body.otp',
        ],
        censor: '[REDACTED]',
      },
    },
  };
}
