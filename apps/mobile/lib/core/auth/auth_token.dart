// ignore_for_file: public_member_api_docs

/// In-memory holder for the mobile access token used in `Authorization: Bearer`
/// requests (FW-02).
///
/// Foundation seam only: web never reads this (it relies on HttpOnly cookies),
/// and the `flutter_secure_storage`-backed implementation arrives with the
/// Sprint 2 login screen. Modern non-codegen Riverpod is used deliberately —
/// see docs/adrs/009-riverpod-without-codegen.md.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

final accessTokenProvider = NotifierProvider<AccessTokenNotifier, String?>(
  AccessTokenNotifier.new,
);

class AccessTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? token) => state = token;

  void clear() => state = null;
}
