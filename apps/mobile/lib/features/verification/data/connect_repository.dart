// ignore_for_file: public_member_api_docs

/// Wraps the tasker Stripe Connect payout endpoints (`/me/connect/*`). Screens
/// go through this, never dio directly (apps/mobile CLAUDE.md rule 2). The
/// mutating onboard call carries an `Idempotency-Key`.
library;

import 'package:dio/dio.dart';

import '../models/connect_status.dart';

class ConnectRepository {
  ConnectRepository(this._dio, {required this.newIdempotencyKey});

  final Dio _dio;
  final String Function() newIdempotencyKey;

  /// Current payout-onboarding status for the tasker.
  Future<ConnectStatus> fetchStatus() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/connect/status');
    return ConnectStatus.fromJson(res.data ?? const {});
  }

  /// Starts (or continues) Stripe Connect onboarding and returns the
  /// Stripe-hosted account-link URL to open in a browser. Mutating — creates the
  /// Connect account on first call — so it carries an idempotency key.
  Future<String> startOnboarding() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/me/connect/onboard',
      options: Options(headers: {'Idempotency-Key': newIdempotencyKey()}),
    );
    final url = (res.data ?? const {})['url'];
    if (url is! String || url.isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Connect onboarding link missing from response',
      );
    }
    return url;
  }
}
