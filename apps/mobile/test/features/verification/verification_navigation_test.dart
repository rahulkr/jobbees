// Guards the hierarchical navigation into the tasker verification forms. These
// screens pop() on success, so they MUST be pushed (not context.go, which
// replaces the stack and leaves nothing to pop / no back button). Regression
// cover for the "Add your ABN has no back button" bug.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jobbees_mobile/features/verification/models/abn_status.dart';
import 'package:jobbees_mobile/features/verification/providers/verification_providers.dart';
import 'package:jobbees_mobile/features/verification/screens/abn_entry_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeAbn extends AbnStatusController {
  @override
  Future<AbnStatus> build() async => const AbnStatus();
}

void main() {
  testWidgets(
    'Add ABN is pushed — shows a back button and pops back to the hub',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/verify',
        routes: [
          GoRoute(
            path: '/verify',
            builder: (context, state) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.push('/verify/abn'),
                  child: const Text('Add ABN'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/verify/abn',
            builder: (context, state) => const AbnEntryScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [abnStatusProvider.overrideWith(_FakeAbn.new)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add ABN'));
      await tester.pumpAndSettle();

      // Pushed route → the form is shown WITH a back affordance (JAppBar's
      // JPressable chevron, not Material's default BackButton).
      expect(find.text('Add your ABN'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronLeft), findsOneWidget);

      // Back returns to the hub (proves it stacked, not replaced).
      await tester.tap(find.byIcon(LucideIcons.chevronLeft));
      await tester.pumpAndSettle();
      expect(find.text('Add ABN'), findsOneWidget);
      expect(find.text('Add your ABN'), findsNothing);
    },
  );
}
