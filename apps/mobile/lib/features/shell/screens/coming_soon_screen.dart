// ignore_for_file: public_member_api_docs

/// A designed "coming soon" tab for bottom-nav destinations whose real feature
/// lands in a later sprint (Offers, Messages). Replaces the dev
/// [PlaceholderScreen] on live tabs so a user never sees a bare scaffold or
/// developer instrumentation — just a branded empty state.
library;

import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: JEntrance(
            child: JEmptyState(icon: icon, title: title, body: body),
          ),
        ),
      ),
    );
  }
}
