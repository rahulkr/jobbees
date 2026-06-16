import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:jobbees_mobile/ui/ui.dart';

WidgetbookComponent jCardPage() {
  return WidgetbookComponent(
    name: 'JCard',
    useCases: [
      WidgetbookUseCase(
        name: 'Default (flat with border)',
        builder: (ctx) => _frame(JCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Fence repair — Newtown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: JSpacing.xs),
              Text('Three damaged panels, need replacement.', style: TextStyle(fontSize: 14)),
              SizedBox(height: JSpacing.sm),
              Text('\$180 budget · 2.1 km away', style: TextStyle(fontSize: 12)),
            ],
          ),
        )),
      ),
      WidgetbookUseCase(
        name: 'Tappable (list card)',
        builder: (ctx) => _frame(JCard.tappable(
          onTap: () {},
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE5D6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.build, color: Color(0xFFFF6B2C)),
              ),
              const SizedBox(width: JSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Assemble Ikea bookshelf', style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('Surry Hills · Tomorrow', style: TextStyle(fontSize: 12, color: Color(0xFF5A5A6E))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        )),
      ),
      WidgetbookUseCase(
        name: 'Elevated (modal-like)',
        builder: (ctx) => _frame(JCard.elevated(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 48),
              SizedBox(height: JSpacing.base),
              Text('Payment authorised', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: JSpacing.xs),
              Text('\$84 will release when work is complete', style: TextStyle(fontSize: 14)),
            ],
          ),
        )),
      ),
    ],
  );
}

Widget _frame(Widget child) => Padding(
      padding: const EdgeInsets.all(JSpacing.base),
      child: child,
    );
