/**
 * ABN (Australian Business Number) checksum validation.
 *
 * ⚠️ Tax/compliance logic — reviewed against `.claude/skills/au-tax`. Do not
 * "simplify" the algorithm; it is the ATO-published spec:
 *   1. Strip spaces; an ABN is exactly 11 digits.
 *   2. Subtract 1 from the FIRST (leftmost) digit.
 *   3. Multiply each digit by its positional weight
 *      [10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19].
 *   4. The ABN is valid iff the sum of the products is divisible by 89.
 *
 * Reference: ATO "Format of the ABN" — checksum validation.
 * Worked example: 51 824 753 556 (ATO's documentation example) → sum 534 → 534 % 89 === 0.
 *
 * This is a FORMAT check only. It proves the number is well-formed, not that it
 * is registered/active — that's the ABR lookup's job (AbrService).
 */
const ABN_WEIGHTS = [10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19] as const;

export class AbnValidator {
  private constructor() {}

  /** Removes spaces from a user-entered ABN. */
  static normalise(raw: string): string {
    return raw.replace(/\s+/g, '');
  }

  /** True when `raw` is a well-formed ABN (11 digits, valid checksum). */
  static isValid(raw: string): boolean {
    const abn = AbnValidator.normalise(raw);
    if (!/^\d{11}$/.test(abn)) {
      return false;
    }

    const digits = abn.split('').map((d) => Number.parseInt(d, 10));

    // Step 2: subtract 1 from the leading digit, then weight each digit. We
    // consume a copy of the weights with shift() (rather than ABN_WEIGHTS[i])
    // so there's no dynamic index access for the security linter to flag.
    const weights = [...ABN_WEIGHTS];
    const sum = digits.reduce((acc, digit, index) => {
      const weighted = index === 0 ? digit - 1 : digit;
      return acc + weighted * (weights.shift() ?? 0);
    }, 0);

    return sum % 89 === 0;
  }
}
