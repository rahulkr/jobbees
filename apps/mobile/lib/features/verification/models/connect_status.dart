// ignore_for_file: public_member_api_docs

/// Tasker Stripe Connect payout-onboarding status, mirroring the API's
/// ConnectStatusDto (`GET /me/connect/status`).
library;

import 'package:flutter/foundation.dart';

/// Payout-onboarding state. Values mirror the API `ConnectStatus` enum; an
/// unrecognised value maps to [unknown] so a server change can't crash the app.
enum ConnectState {
  notStarted,
  pending,
  complete,
  restricted,
  unknown;

  static ConnectState fromApi(String? raw) => switch (raw) {
    'NOT_STARTED' => ConnectState.notStarted,
    'PENDING' => ConnectState.pending,
    'COMPLETE' => ConnectState.complete,
    'RESTRICTED' => ConnectState.restricted,
    _ => ConnectState.unknown,
  };
}

@immutable
class ConnectStatus {
  const ConnectStatus({
    required this.state,
    required this.payoutsEnabled,
    required this.detailsSubmitted,
  });

  factory ConnectStatus.fromJson(Map<String, dynamic> json) => ConnectStatus(
    state: ConnectState.fromApi(json['status'] as String?),
    payoutsEnabled: json['payoutsEnabled'] as bool? ?? false,
    detailsSubmitted: json['detailsSubmitted'] as bool? ?? false,
  );

  final ConnectState state;
  final bool payoutsEnabled;
  final bool detailsSubmitted;

  /// Payout setup hasn't been started yet.
  bool get isNotStarted => state == ConnectState.notStarted;

  /// Onboarding started but Stripe hasn't enabled payouts yet.
  bool get isPending => state == ConnectState.pending;

  /// Fully onboarded — payouts enabled.
  bool get isComplete => state == ConnectState.complete;

  /// Stripe needs more information / has flagged the account.
  bool get isRestricted => state == ConnectState.restricted;

  /// Whether to nudge the tasker to (finish) payout setup.
  bool get needsSetup => !isComplete;
}
