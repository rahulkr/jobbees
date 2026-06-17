import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:jobbees_mobile/ui/ui.dart';

WidgetbookComponent jBottomSheetPage() {
  return WidgetbookComponent(
    name: 'JBottomSheet',
    useCases: [
      WidgetbookUseCase(
        name: 'Trigger demo (tap to show)',
        builder: (ctx) => _frame(
          JButton.primary(
            label: 'Show withdraw-offer sheet',
            onPressed: () => JBottomSheet.show(
              context: ctx,
              title: 'Withdraw your offer?',
              child: const Text(
                'The client will no longer see your offer. You can place a new one later if you change your mind.',
                style: TextStyle(fontSize: 14),
              ),
              primaryAction: JButton.danger(
                label: 'Yes, withdraw',
                onPressed: () => Navigator.pop(ctx),
                expanded: true,
              ),
              secondaryAction: JButton.secondary(
                label: 'Keep it open',
                onPressed: () => Navigator.pop(ctx),
                expanded: true,
              ),
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Trigger demo — payment confirm',
        builder: (ctx) => _frame(
          JButton.primary(
            label: 'Show payment confirm sheet',
            onPressed: () => JBottomSheet.show(
              context: ctx,
              title: 'Pay \$84 now?',
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your card will be charged when the tasker marks the job complete and you confirm.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: JSpacing.base),
                  Text(
                    'Visa ending 4242',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              primaryAction: JButton.primary(
                label: 'Yes, pay \$84',
                onPressed: () => Navigator.pop(ctx),
                expanded: true,
              ),
              secondaryAction: JButton.ghost(
                label: 'Not yet',
                onPressed: () => Navigator.pop(ctx),
                expanded: true,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _frame(Widget child) => Center(
  child: Padding(padding: const EdgeInsets.all(JSpacing.base), child: child),
);
