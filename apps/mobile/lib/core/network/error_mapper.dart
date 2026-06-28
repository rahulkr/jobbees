// ignore_for_file: public_member_api_docs

/// Converts low-level errors (mostly [DioException]) into a user-facing message
/// (apps/mobile CLAUDE.md rule 8 — network errors render as the error state,
/// never silently swallowed).
///
/// The API is NestJS, so error bodies follow `{ statusCode, message, error }`
/// where `message` is a string or a string[] (class-validator). We surface the
/// server message when present and fall back to a friendly status-based line.
library;

import 'package:dio/dio.dart';

/// A user-presentable error. Screens show `.message` in their error state.
class AppError implements Exception {
  const AppError(this.message, {this.retryable = false});

  final String message;

  /// Whether re-running the same request might succeed without the user
  /// changing anything: a transient failure (no connection, timeout, or a 5xx).
  /// Validation / auth errors (4xx) are NOT retryable — retrying just fails
  /// again — so a "Retry" affordance should only show when this is true.
  final bool retryable;

  @override
  String toString() => message;
}

class ErrorMapper {
  ErrorMapper._();

  static AppError map(Object error) {
    if (error is AppError) return error;
    if (error is DioException) return _fromDio(error);
    return const AppError('Something went wrong. Please try again.');
  }

  static AppError _fromDio(DioException error) {
    final response = error.response;
    if (response != null) {
      final status = response.statusCode;
      return AppError(
        _serverMessage(response.data) ?? _statusFallback(status),
        // Server-side faults (5xx) are worth retrying; 4xx are the caller's
        // problem and won't fix themselves on a retry.
        retryable: status != null && status >= 500,
      );
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const AppError(
        'The connection timed out. Check your network and try again.',
        retryable: true,
      ),
      DioExceptionType.connectionError => const AppError(
        "Can't reach JOBBees right now. Check your connection and try again.",
        retryable: true,
      ),
      _ => const AppError(
        'Something went wrong. Please try again.',
        retryable: true,
      ),
    };
  }

  static String? _serverMessage(dynamic data) {
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
    }
    return null;
  }

  static String _statusFallback(int? status) => switch (status) {
    400 => 'Please check the details you entered and try again.',
    401 => 'Your session has expired. Please sign in again.',
    403 => 'You do not have access to that.',
    409 => 'That account already exists.',
    429 => 'Too many attempts. Please wait a minute and try again.',
    final s? when s >= 500 =>
      'JOBBees is having a moment. Please try again shortly.',
    _ => 'Something went wrong. Please try again.',
  };
}
