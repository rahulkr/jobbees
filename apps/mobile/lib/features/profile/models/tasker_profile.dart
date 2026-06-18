// ignore_for_file: public_member_api_docs

/// Tasker profile (bio, hourly rate in cents, free-text skill tags). Manual
/// JSON, no codegen (ADR 009).
library;

import 'package:flutter/foundation.dart';

@immutable
class TaskerProfile {
  const TaskerProfile({this.bio, this.hourlyRateCents, this.skills = const []});

  final String? bio;
  final int? hourlyRateCents;
  final List<String> skills;

  factory TaskerProfile.fromJson(Map<String, dynamic> json) => TaskerProfile(
    bio: json['bio'] as String?,
    hourlyRateCents: (json['hourlyRateCents'] as num?)?.toInt(),
    skills:
        (json['skills'] as List?)?.map((e) => e as String).toList() ?? const [],
  );
}
