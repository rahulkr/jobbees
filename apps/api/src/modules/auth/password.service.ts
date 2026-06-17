import { Injectable } from '@nestjs/common';
import * as argon2 from 'argon2';

/**
 * Password hashing — argon2id only (CLAUDE.md security rule; never bcrypt/sha).
 */
@Injectable()
export class PasswordService {
  hash(plain: string): Promise<string> {
    return argon2.hash(plain, { type: argon2.argon2id });
  }

  async verify(hash: string, plain: string): Promise<boolean> {
    try {
      return await argon2.verify(hash, plain);
    } catch {
      // Malformed/again-unparseable hash → treat as a failed match, never throw.
      return false;
    }
  }
}
