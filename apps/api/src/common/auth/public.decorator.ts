import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'jobbees:public';

/**
 * Marks a route as not requiring authentication. The globally-applied
 * JwtAuthGuard skips routes (or whole controllers) tagged with this.
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
