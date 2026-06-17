import { Injectable, NestMiddleware } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';

const MAX_INCOMING_ID_LENGTH = 200;

/**
 * Assigns a request id (honouring an inbound `x-request-id` if present + sane,
 * otherwise a fresh UUID) and echoes it on the response. pino picks it up for
 * log correlation. Uses crypto UUID, never Math.random (CLAUDE.md).
 */
@Injectable()
export class RequestIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction): void {
    const incoming = req.header('x-request-id');
    const id = incoming && incoming.length <= MAX_INCOMING_ID_LENGTH ? incoming : randomUUID();
    (req as Request & { id?: string }).id = id;
    res.setHeader('x-request-id', id);
    next();
  }
}
