import { AbnValidator } from './abn-validator';

describe('AbnValidator', () => {
  it('accepts the ATO documentation example ABN', () => {
    expect(AbnValidator.isValid('51824753556')).toBe(true);
  });

  it('accepts a spaced ABN (normalises whitespace)', () => {
    expect(AbnValidator.isValid('51 824 753 556')).toBe(true);
  });

  it('rejects a number that fails the checksum', () => {
    // Same digits, last one bumped: checksum no longer divisible by 89.
    expect(AbnValidator.isValid('51824753557')).toBe(false);
  });

  it('rejects the wrong length', () => {
    expect(AbnValidator.isValid('5182475355')).toBe(false); // 10 digits
    expect(AbnValidator.isValid('518247535566')).toBe(false); // 12 digits
  });

  it('rejects non-digit characters', () => {
    expect(AbnValidator.isValid('5182475355X')).toBe(false);
    expect(AbnValidator.isValid('')).toBe(false);
  });

  it('normalise strips all whitespace', () => {
    expect(AbnValidator.normalise(' 51 824 753 556 ')).toBe('51824753556');
  });
});
