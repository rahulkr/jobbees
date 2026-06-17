import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:jobbees_mobile/ui/ui.dart';

WidgetbookComponent jEmptyStatePage() {
  return WidgetbookComponent(
    name: 'JEmptyState',
    useCases: [
      WidgetbookUseCase(
        name: 'No jobs yet (Client home)',
        builder: (ctx) => JEmptyState(
          icon: Icons.outbox_outlined,
          title: 'No jobs near you yet',
          body:
              'Be the first to post one. We will send it to taskers in your suburb.',
          primaryAction: JButton.primary(label: 'Post a job', onPressed: () {}),
        ),
      ),
      WidgetbookUseCase(
        name: 'No offers yet (Job detail)',
        builder: (ctx) => JEmptyState(
          icon: Icons.work_outline,
          title: 'No offers yet',
          body:
              'Most jobs get their first offer within 2 hours. You can edit the job while you wait.',
          primaryAction: JButton.primary(label: 'Edit job', onPressed: () {}),
          secondaryAction: JButton.ghost(
            label: 'Tasker invite settings',
            onPressed: () {},
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Not a tasker yet',
        builder: (ctx) => JEmptyState(
          icon: Icons.handyman_outlined,
          title: "You haven't been a tasker before",
          body:
              'Get verified once with Stripe, then offer on any job. Takes 5 minutes.',
          primaryAction: JButton.primary(
            label: 'Become a tasker',
            onPressed: () {},
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Quiet inbox',
        builder: (ctx) => const JEmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'Inbox is quiet',
          body:
              'When you have an accepted offer, your conversations with the client or tasker will live here.',
        ),
      ),
      WidgetbookUseCase(
        name: 'No notifications',
        builder: (ctx) => const JEmptyState(
          icon: Icons.notifications_off_outlined,
          title: 'All caught up',
          body:
              "We'll let you know about new offers, accepted bids, and messages.",
        ),
      ),
    ],
  );
}
