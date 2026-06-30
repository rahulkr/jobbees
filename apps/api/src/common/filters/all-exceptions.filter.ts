import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import type { Request, Response } from 'express';

interface ErrorResponseBody {
  statusCode: number;
  error: string;
  message: string | string[];
  /** Optional machine-readable discriminator (e.g. ACCOUNT_SUSPENDED, REAUTH_REQUIRED). */
  code?: string;
  path: string;
  timestamp: string;
}

/**
 * Maps every thrown error to one consistent response envelope.
 *
 * `HttpException`s surface their status + message; anything else becomes a
 * generic 500 (internal details are logged server-side, never leaked to the
 * client). Clients can rely on a stable shape across every endpoint.
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException ? exception.getStatus() : HttpStatus.INTERNAL_SERVER_ERROR;

    let error = 'InternalServerError';
    let message: string | string[] = 'Internal server error';
    let code: string | undefined;

    if (exception instanceof HttpException) {
      const res = exception.getResponse();
      if (typeof res === 'string') {
        message = res;
        error = exception.name;
      } else if (typeof res === 'object' && res !== null) {
        const body = res as Record<string, unknown>;
        message = (body.message as string | string[]) ?? exception.message;
        error = (body.error as string) ?? exception.name;
        // Surface a machine-readable discriminator when the thrower provides one
        // (e.g. ACCOUNT_SUSPENDED, REAUTH_REQUIRED) so clients can branch on it.
        if (typeof body.code === 'string') {
          code = body.code;
        }
      }
    }

    if (status >= HttpStatus.INTERNAL_SERVER_ERROR) {
      this.logger.error(
        `${request.method} ${request.url} -> ${status}`,
        exception instanceof Error ? exception.stack : String(exception),
      );
    }

    const errorBody: ErrorResponseBody = {
      statusCode: status,
      error,
      message,
      ...(code ? { code } : {}),
      path: request.url,
      timestamp: new Date().toISOString(),
    };

    response.status(status).json(errorBody);
  }
}
