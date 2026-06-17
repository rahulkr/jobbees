import { PasswordService } from './password.service';

describe('PasswordService', () => {
  const service = new PasswordService();

  it('hashes with argon2id and verifies the correct password', async () => {
    const hash = await service.hash('correct-horse-battery-staple');
    expect(hash.startsWith('$argon2id$')).toBe(true);
    expect(hash).not.toContain('correct-horse-battery-staple');
    await expect(service.verify(hash, 'correct-horse-battery-staple')).resolves.toBe(true);
  });

  it('rejects an incorrect password', async () => {
    const hash = await service.hash('the-right-one');
    await expect(service.verify(hash, 'the-wrong-one')).resolves.toBe(false);
  });

  it('returns false (never throws) on a malformed hash', async () => {
    await expect(service.verify('not-a-real-hash', 'x')).resolves.toBe(false);
  });
});
