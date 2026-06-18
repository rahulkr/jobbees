// ignore_for_file: public_member_api_docs

/// Wraps the tasker profile endpoints (`/me/profile`). Screens go through this,
/// never dio directly (apps/mobile CLAUDE.md rule 2). The mutating update sends
/// an `Idempotency-Key`.
library;

import 'package:dio/dio.dart';

import '../models/tasker_profile.dart';

class ProfileRepository {
  ProfileRepository(this._dio, {required this.newIdempotencyKey});

  final Dio _dio;
  final String Function() newIdempotencyKey;

  Future<TaskerProfile> fetch() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/profile');
    return TaskerProfile.fromJson(res.data ?? const {});
  }

  Future<TaskerProfile> update({
    String? bio,
    int? hourlyRateCents,
    List<String>? skills,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/me/profile',
      data: {
        if (bio != null) 'bio': bio,
        if (hourlyRateCents != null) 'hourlyRateCents': hourlyRateCents,
        if (skills != null) 'skills': skills,
      },
      options: Options(headers: {'Idempotency-Key': newIdempotencyKey()}),
    );
    return TaskerProfile.fromJson(res.data ?? const {});
  }
}
