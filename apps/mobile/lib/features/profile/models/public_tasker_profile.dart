// ignore_for_file: public_member_api_docs

/// A tasker's public profile as seen by clients (narrow projection — no PII
/// beyond first name + business name). Manual JSON, no codegen (ADR 009).
library;

import 'package:flutter/foundation.dart';

@immutable
class TaskerBadges {
  const TaskerBadges({
    this.email = false,
    this.phone = false,
    this.payments = false,
  });

  final bool email;
  final bool phone;
  final bool payments;

  factory TaskerBadges.fromJson(Map<String, dynamic> json) => TaskerBadges(
    email: json['email'] as bool? ?? false,
    phone: json['phone'] as bool? ?? false,
    payments: json['payments'] as bool? ?? false,
  );
}

@immutable
class PublicTaskerProfile {
  const PublicTaskerProfile({
    required this.id,
    required this.firstName,
    this.avatarUrl,
    this.bio,
    this.hourlyRateCents,
    this.businessName,
    this.skills = const [],
    this.badges = const TaskerBadges(),
  });

  final String id;
  final String firstName;
  final String? avatarUrl;
  final String? bio;
  final int? hourlyRateCents;
  final String? businessName;
  final List<String> skills;
  final TaskerBadges badges;

  factory PublicTaskerProfile.fromJson(Map<String, dynamic> json) =>
      PublicTaskerProfile(
        id: json['id'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        bio: json['bio'] as String?,
        hourlyRateCents: (json['hourlyRateCents'] as num?)?.toInt(),
        businessName: json['businessName'] as String?,
        skills:
            (json['skills'] as List?)?.map((e) => e as String).toList() ??
            const [],
        badges: TaskerBadges.fromJson(
          (json['verified'] as Map<String, dynamic>?) ?? const {},
        ),
      );
}
