// ignore_for_file: public_member_api_docs

/// Stripe Connect payout providers + status controller (ADR 009 — no codegen).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/network/idempotency.dart';
import '../data/connect_repository.dart';
import '../models/connect_status.dart';

final connectRepositoryProvider = Provider<ConnectRepository>(
  (ref) => ConnectRepository(
    ref.watch(dioProvider),
    newIdempotencyKey: generateIdempotencyKey,
  ),
);

/// Opens an external URL. The real impl uses `SFSafariViewController` (iOS) /
/// Chrome Custom Tabs (Android) via `LaunchMode.inAppBrowserView` — Stripe's
/// recommended host for Account Links, not a raw webview (which Stripe may
/// block). Overridable in tests so no browser is launched.
typedef UrlOpener = Future<void> Function(Uri url);

final urlOpenerProvider = Provider<UrlOpener>(
  (ref) => (url) async {
    await launchUrl(url, mode: LaunchMode.inAppBrowserView);
  },
);

/// Loads + holds the tasker's Connect payout status. `loading` while fetching;
/// the hub renders state-by-state. [beginOnboarding] fetches a fresh Stripe
/// account link and opens it; the hub calls [refresh] when the tasker returns.
final connectStatusProvider =
    AsyncNotifierProvider<ConnectStatusController, ConnectStatus>(
      ConnectStatusController.new,
    );

class ConnectStatusController extends AsyncNotifier<ConnectStatus> {
  @override
  Future<ConnectStatus> build() =>
      ref.read(connectRepositoryProvider).fetchStatus();

  /// Starts (or continues) onboarding and opens the Stripe-hosted link. Rethrows
  /// as [AppError] for the card to show. Status isn't changed here — it refreshes
  /// when the tasker returns from the browser.
  Future<void> beginOnboarding() async {
    try {
      final url = await ref.read(connectRepositoryProvider).startOnboarding();
      await Analytics.track('connect_onboarding_started');
      await ref.read(urlOpenerProvider)(Uri.parse(url));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Re-fetches status without a full spinner reset — used when the tasker
  /// returns from the hosted flow (app resume) so a completed onboarding flips
  /// the card without a jarring reload.
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(connectRepositoryProvider).fetchStatus(),
    );
  }
}
