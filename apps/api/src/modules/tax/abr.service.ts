import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NodeEnv } from '../../config/env.validation';
import { RedisService } from '../../redis/redis.service';

/** Normalised result of an ABR (Australian Business Register) lookup. */
export interface AbrResult {
  abn: string;
  businessName: string;
  isActive: boolean;
  gstRegistered: boolean;
}

/** 24h cache — ABR registration data changes rarely; protects the 1k/day quota. */
const CACHE_TTL_SECONDS = 24 * 60 * 60;
const ABR_BASE_URL = 'https://abr.business.gov.au/json/AbnDetails.aspx';

/**
 * Looks up business details from the ABR.
 *
 * The GUID is obtained by registering (free) at abr.business.gov.au. When it is
 * not configured we fall back to a deterministic stub in NON-production so the
 * ABN flow stays testable without the live register; in production a missing
 * GUID means we simply cannot confirm the business name (returns null) rather
 * than blocking.
 *
 * ⚠️ au-tax: never log the GUID. The live JSONP response shape is parsed
 * defensively and SHOULD be verified end-to-end against a real GUID before
 * relying on it in production.
 */
@Injectable()
export class AbrService {
  private readonly logger = new Logger(AbrService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly redis: RedisService,
  ) {}

  private get guid(): string {
    return this.config.get<string>('ABR_GUID', '');
  }

  private get isProduction(): boolean {
    return this.config.get<string>('NODE_ENV') === NodeEnv.Production;
  }

  async lookup(abn: string): Promise<AbrResult | null> {
    const cacheKey = `abr:${abn}`;
    const cached = await this.redis.client.get(cacheKey);
    if (cached) {
      return JSON.parse(cached) as AbrResult;
    }

    const result = await this.fetchResult(abn);
    if (result) {
      await this.redis.client.set(cacheKey, JSON.stringify(result), 'EX', CACHE_TTL_SECONDS);
    }
    return result;
  }

  private async fetchResult(abn: string): Promise<AbrResult | null> {
    if (!this.guid) {
      if (this.isProduction) {
        this.logger.warn('ABR_GUID not configured; skipping ABR lookup');
        return null;
      }
      return this.stub(abn);
    }

    try {
      const url = `${ABR_BASE_URL}?abn=${encodeURIComponent(abn)}&guid=${encodeURIComponent(this.guid)}`;
      const response = await fetch(url);
      if (!response.ok) {
        this.logger.warn(`ABR lookup failed with status ${response.status}`);
        return null;
      }
      return this.parse(abn, await response.text());
    } catch (error) {
      // Never let an ABR outage block the user; surface as "unverified".
      this.logger.warn(`ABR lookup error: ${error instanceof Error ? error.message : 'unknown'}`);
      return null;
    }
  }

  /**
   * The endpoint returns JSONP (`callback({...})`). Strip the wrapper and read
   * the fields we need, tolerating absent keys.
   */
  private parse(abn: string, body: string): AbrResult | null {
    const start = body.indexOf('{');
    const end = body.lastIndexOf('}');
    if (start === -1 || end === -1) return null;

    let payload: Record<string, unknown>;
    try {
      payload = JSON.parse(body.slice(start, end + 1)) as Record<string, unknown>;
    } catch {
      return null;
    }

    const entityName =
      (payload.EntityName as string | undefined) ??
      (payload.BusinessName as string | undefined) ??
      '';
    if (!entityName) return null;

    const status = (payload.AbnStatus as string | undefined) ?? '';
    const gst = (payload.Gst as string | undefined) ?? '';

    return {
      abn,
      businessName: entityName,
      isActive: status.toLowerCase() === 'active',
      gstRegistered: gst.length > 0,
    };
  }

  /** Non-production stand-in so the flow is demo/test-able without a GUID. */
  private stub(abn: string): AbrResult {
    return {
      abn,
      businessName: 'Test Business Pty Ltd',
      isActive: true,
      gstRegistered: true,
    };
  }
}
