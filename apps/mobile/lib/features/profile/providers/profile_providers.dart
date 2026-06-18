// ignore_for_file: public_member_api_docs

/// Tasker profile providers + controller (ADR 009 — no codegen).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/network/idempotency.dart';
import '../data/profile_repository.dart';
import '../models/tasker_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    ref.watch(dioProvider),
    newIdempotencyKey: generateIdempotencyKey,
  ),
);

/// Loads + holds the tasker profile. [save] persists the edited fields and
/// replaces state with the server's response; failures rethrow as [AppError].
final taskerProfileControllerProvider =
    AsyncNotifierProvider<TaskerProfileController, TaskerProfile>(
      TaskerProfileController.new,
    );

class TaskerProfileController extends AsyncNotifier<TaskerProfile> {
  @override
  Future<TaskerProfile> build() => ref.read(profileRepositoryProvider).fetch();

  Future<void> save({
    required String bio,
    required int? hourlyRateCents,
    required List<String> skills,
  }) async {
    try {
      final updated = await ref
          .read(profileRepositoryProvider)
          .update(bio: bio, hourlyRateCents: hourlyRateCents, skills: skills);
      state = AsyncData(updated);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
