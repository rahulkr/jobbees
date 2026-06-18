import { BadRequestException } from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
import type { Request } from 'express';
import type { RedisService } from '../../redis/redis.service';
import type { StripeConnectService } from './stripe-connect.service';
import { StripeWebhooksController } from './stripe-webhooks.controller';

function build() {
  const connect = {
    constructEvent: jest.fn(),
    handleEvent: jest.fn().mockResolvedValue(undefined),
  };
  const redis = { client: { set: jest.fn().mockResolvedValue('OK') } };
  const controller = new StripeWebhooksController(
    connect as unknown as StripeConnectService,
    redis as unknown as RedisService,
  );
  return { controller, connect, redis };
}

const req = (rawBody?: Buffer): RawBodyRequest<Request> =>
  ({ rawBody }) as unknown as RawBodyRequest<Request>;

describe('StripeWebhooksController', () => {
  it('rejects a missing body or signature', async () => {
    const { controller, connect } = build();

    await expect(controller.handle(req(undefined), 'sig')).rejects.toBeInstanceOf(
      BadRequestException,
    );
    await expect(controller.handle(req(Buffer.from('{}')), undefined)).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(connect.constructEvent).not.toHaveBeenCalled();
  });

  it('rejects an invalid signature without dispatching', async () => {
    const { controller, connect, redis } = build();
    connect.constructEvent.mockImplementation(() => {
      throw new Error('bad sig');
    });

    await expect(controller.handle(req(Buffer.from('{}')), 'sig')).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(connect.handleEvent).not.toHaveBeenCalled();
    expect(redis.client.set).not.toHaveBeenCalled();
  });

  it('verifies, dedupes, and dispatches a fresh event', async () => {
    const { controller, connect, redis } = build();
    connect.constructEvent.mockReturnValue({ id: 'evt_1', type: 'account.updated' });

    const result = await controller.handle(req(Buffer.from('{}')), 'sig');

    expect(redis.client.set).toHaveBeenCalledWith(
      'stripe:evt:evt_1',
      '1',
      'EX',
      expect.any(Number),
      'NX',
    );
    expect(connect.handleEvent).toHaveBeenCalledTimes(1);
    expect(result).toEqual({ received: true });
  });

  it('skips an already-seen event (dedupe)', async () => {
    const { controller, connect, redis } = build();
    connect.constructEvent.mockReturnValue({ id: 'evt_1', type: 'account.updated' });
    redis.client.set.mockResolvedValue(null); // NX failed → already processed

    await controller.handle(req(Buffer.from('{}')), 'sig');

    expect(connect.handleEvent).not.toHaveBeenCalled();
  });
});
