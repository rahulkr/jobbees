// ignore_for_file: public_member_api_docs

/// Tasker ABN verification status, mirroring the API's AbnStatusDto.
library;

import 'package:flutter/foundation.dart';

@immutable
class AbnStatus {
  const AbnStatus({this.abn, this.businessName, this.verifiedAt});

  factory AbnStatus.fromJson(Map<String, dynamic> json) => AbnStatus(
    abn: json['abn'] as String?,
    businessName: json['businessName'] as String?,
    verifiedAt: switch (json['verifiedAt']) {
      final String s => DateTime.tryParse(s),
      _ => null,
    },
  );

  final String? abn;
  final String? businessName;
  final DateTime? verifiedAt;

  /// No ABN on file yet.
  bool get isEmpty => abn == null;

  /// ABN submitted and confirmed active on the ABR.
  bool get isVerified => verifiedAt != null;

  /// ABN submitted but not yet confirmed (ABR couldn't confirm / unavailable).
  bool get isPending => abn != null && verifiedAt == null;
}
