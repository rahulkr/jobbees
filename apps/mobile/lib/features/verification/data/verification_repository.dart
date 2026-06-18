// ignore_for_file: public_member_api_docs

/// Wraps the tasker verification endpoints (`/me/abn`). Screens go through this,
/// never dio directly (apps/mobile CLAUDE.md rule 2). The `Idempotency-Key` is
/// attached on the mutating submit.
library;

import 'package:dio/dio.dart';

import '../models/abn_status.dart';

class VerificationRepository {
  VerificationRepository(this._dio, {required this.newIdempotencyKey});

  final Dio _dio;
  final String Function() newIdempotencyKey;

  Future<AbnStatus> fetchAbnStatus() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/abn');
    return AbnStatus.fromJson(res.data ?? const {});
  }

  Future<AbnStatus> submitAbn(String abn) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/me/abn',
      data: {'abn': abn},
      options: Options(headers: {'Idempotency-Key': newIdempotencyKey()}),
    );
    return AbnStatus.fromJson(res.data ?? const {});
  }

  /// Sends a phone OTP to [phone] (tasker only). Dev accepts code `000000`.
  Future<void> sendPhoneOtp(String phone) async {
    await _dio.post<void>(
      '/auth/otp/send',
      data: {'phone': phone},
      options: Options(headers: {'Idempotency-Key': newIdempotencyKey()}),
    );
  }

  /// Verifies the OTP [code] for [phone]; on success the server marks the
  /// account's phone verified.
  Future<void> verifyPhoneOtp({
    required String phone,
    required String code,
  }) async {
    await _dio.post<void>(
      '/auth/otp/verify',
      data: {'phone': phone, 'code': code},
      options: Options(headers: {'Idempotency-Key': newIdempotencyKey()}),
    );
  }
}
