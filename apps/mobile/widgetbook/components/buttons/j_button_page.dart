import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:jobbees_mobile/ui/ui.dart';

WidgetbookComponent jButtonPage() {
  return WidgetbookComponent(
    name: 'JButton',
    useCases: [
      // --- Primary ---
      WidgetbookUseCase(
        name: 'Primary — idle',
        builder: (ctx) => _frame(JButton.primary(
          label: 'Post a job',
          onPressed: () {},
        )),
      ),
      WidgetbookUseCase(
        name: 'Primary — disabled',
        builder: (ctx) => _frame(JButton.primary(
          label: 'Post a job',
          onPressed: null,
        )),
      ),
      WidgetbookUseCase(
        name: 'Primary — loading',
        builder: (ctx) => _frame(JButton.primary(
          label: 'Posting...',
          onPressed: null,
          loading: true,
        )),
      ),
      WidgetbookUseCase(
        name: 'Primary — with icon',
        builder: (ctx) => _frame(JButton.primary(
          label: 'Continue with Apple',
          onPressed: () {},
          icon: Icons.apple,
        )),
      ),
      WidgetbookUseCase(
        name: 'Primary — expanded',
        builder: (ctx) => _frame(JButton.primary(
          label: 'Pay \$84',
          onPressed: () {},
          expanded: true,
        )),
      ),
      WidgetbookUseCase(
        name: 'Primary — gradient (hero moment)',
        builder: (ctx) => _frame(JButton.primary(
          label: 'Make an offer',
          onPressed: () {},
          gradient: true,
          expanded: true,
        )),
      ),

      // --- Secondary ---
      WidgetbookUseCase(
        name: 'Secondary — idle',
        builder: (ctx) => _frame(JButton.secondary(
          label: "I'll do it later",
          onPressed: () {},
        )),
      ),

      // --- Danger ---
      WidgetbookUseCase(
        name: 'Danger — idle (Conversational confirm per VOICE.md)',
        builder: (ctx) => _frame(JButton.danger(
          label: 'Yes, delete it',
          onPressed: () {},
        )),
      ),

      // --- Ghost ---
      WidgetbookUseCase(
        name: 'Ghost — idle',
        builder: (ctx) => _frame(JButton.ghost(
          label: 'Skip for now',
          onPressed: () {},
        )),
      ),

      // --- Sizes ---
      WidgetbookUseCase(
        name: 'Sizes — sm / md / lg',
        builder: (ctx) => _frame(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JButton.primary(label: 'Small', onPressed: () {}, size: JButtonSize.sm),
              const SizedBox(height: JSpacing.sm),
              JButton.primary(label: 'Medium (default)', onPressed: () {}),
              const SizedBox(height: JSpacing.sm),
              JButton.primary(label: 'Large', onPressed: () {}, size: JButtonSize.lg),
            ],
          ),
        ),
      ),

      // --- Compose example ---
      WidgetbookUseCase(
        name: 'Compose — confirm modal pair',
        builder: (ctx) => _frame(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              JButton.danger(label: 'Yes, withdraw', onPressed: () {}, expanded: true),
              const SizedBox(height: JSpacing.sm),
              JButton.secondary(label: 'Keep it open', onPressed: () {}, expanded: true),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _frame(Widget child) => Padding(
      padding: const EdgeInsets.all(JSpacing.base),
      child: Center(child: child),
    );
