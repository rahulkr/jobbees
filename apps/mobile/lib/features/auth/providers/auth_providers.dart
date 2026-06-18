// ignore_for_file: public_member_api_docs

/// Auth dependency providers (ADR 009 — plain Provider, no codegen).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/token_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/idempotency.dart';
import '../data/auth_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(dioProvider),
    newIdempotencyKey: generateIdempotencyKey,
  ),
);
