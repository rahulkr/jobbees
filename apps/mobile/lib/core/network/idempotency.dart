// ignore_for_file: public_member_api_docs

/// Idempotency-Key generation for mutating API calls.
///
/// The API requires an `Idempotency-Key` header on every mutating endpoint
/// (root CLAUDE.md rule 3) and replays the cached response on retry. The key
/// only needs to be unique; we use `Random.secure()` (over `Random()`) to keep
/// well clear of the "no Math.random for sensitive values" rule, even though a
/// collision here is merely a correctness, not a security, concern.
library;

import 'dart:math';

final Random _rng = Random.secure();

/// A v4-shaped UUID string, e.g. `3f1c…-…`. Format mirrors RFC 4122 so it reads
/// like the keys other surfaces send; only uniqueness is load-bearing.
String generateIdempotencyKey() {
  final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
