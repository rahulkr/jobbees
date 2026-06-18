// ignore_for_file: public_member_api_docs

/// Verification providers + ABN status controller (ADR 009 — no codegen).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/network/idempotency.dart';
import '../data/verification_repository.dart';
import '../models/abn_status.dart';

final verificationRepositoryProvider = Provider<VerificationRepository>(
  (ref) => VerificationRepository(
    ref.watch(dioProvider),
    newIdempotencyKey: generateIdempotencyKey,
  ),
);

/// Loads + holds the tasker's ABN status. `loading` while fetching; the screen
/// renders state-by-state. [submit] posts a new ABN and replaces the state with
/// the result; failures are rethrown as [AppError] for the form to show.
final abnStatusProvider = AsyncNotifierProvider<AbnStatusController, AbnStatus>(
  AbnStatusController.new,
);

class AbnStatusController extends AsyncNotifier<AbnStatus> {
  @override
  Future<AbnStatus> build() =>
      ref.read(verificationRepositoryProvider).fetchAbnStatus();

  Future<void> submit(String abn) async {
    try {
      final status = await ref
          .read(verificationRepositoryProvider)
          .submitAbn(abn);
      state = AsyncData(status);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
