/// Haptic feedback wrapper — single source of truth for "what haptic on what action."
///
/// Reference: `docs/brand/UI-PRINCIPLES.md` § Haptics table.
///
/// Every interactive moment in the app should call one of these methods,
/// not raw `HapticFeedback.lightImpact()`.

library;

import 'package:flutter/services.dart';

class JHaptics {
  JHaptics._();

  /// Tasker tapped Place Offer.
  /// Soft confirmation — the action started.
  static Future<void> offerPlaced() => HapticFeedback.lightImpact();

  /// Client tapped Accept Offer.
  /// Medium — the action committed.
  static Future<void> offerAccepted() => HapticFeedback.mediumImpact();

  /// Payment was authorised on Stripe.
  /// Medium — money committed.
  static Future<void> paymentAuthorised() => HapticFeedback.mediumImpact();

  /// Job marked complete.
  /// Heavy — the celebration moment.
  static Future<void> jobCompleted() => HapticFeedback.heavyImpact();

  /// Form validation failed / payment declined / error toast appeared.
  /// Long buzz — get the user's attention.
  static Future<void> error() => HapticFeedback.vibrate();

  /// Tab switch, chip select, segmented control change.
  /// Subtle click — UI navigation.
  static Future<void> navigation() => HapticFeedback.selectionClick();
}
