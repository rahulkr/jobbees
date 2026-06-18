import {
  BadRequestException,
  Controller,
  Headers,
  HttpCode,
  HttpStatus,
  Post,
  Req,
} from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import type { RawBodyRequest } from '@nestjs/common';
import type { Request } from 'express';
import { Public } from '../../common/auth/public.decorator';
import { SkipIdempotency } from '../../common/idempotency/skip-idempotency.decorator';
import { RedisService } from '../../redis/redis.service';
import { StripeConnectService } from './stripe-connect.service';

const EVENT_DEDUPE_TTL_SECONDS = 60 * 60 * 24;

/**
 * Stripe webhook receiver. Public (Stripe is unauthenticated) but the signature
 * is verified against the raw body before anything runs (stripe-payment skill
 * rule 4 / security-review H5). Skips the idempotency interceptor — Stripe sends
 * no Idempotency-Key; we dedupe by event id instead. Returns 200 fast.
 */
@ApiExcludeController()
@Controller('webhooks')
export class StripeWebhooksController {
  constructor(
    private readonly connect: StripeConnectService,
    private readonly redis: RedisService,
  ) {}

  @Post('stripe')
  @Public()
  @SkipIdempotency()
  @HttpCode(HttpStatus.OK)
  async handle(
    @Req() req: RawBodyRequest<Request>,
    @Headers('stripe-signature') signature?: string,
  ): Promise<{ received: true }> {
    const raw = req.rawBody;
    if (!raw || !signature) {
      throw new BadRequestException('Missing webhook body or signature');
    }

    let event: ReturnType<typeof this.connect.constructEvent>;
    try {
      event = this.connect.constructEvent(raw, signature);
    } catch {
      // Never reveal verification internals; just reject.
      throw new BadRequestException('Invalid webhook signature');
    }

    // Dedupe: Stripe retries, so only process each event id once.
    const fresh = await this.redis.client.set(
      `stripe:evt:${event.id}`,
      '1',
      'EX',
      EVENT_DEDUPE_TTL_SECONDS,
      'NX',
    );
    if (fresh !== 'OK') return { received: true };

    await this.connect.handleEvent(event);
    return { received: true };
  }
}
