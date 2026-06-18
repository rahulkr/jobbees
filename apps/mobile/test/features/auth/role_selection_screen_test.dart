import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jobbees_mobile/features/auth/models/auth_models.dart';
import 'package:jobbees_mobile/features/auth/screens/role_selection_screen.dart';
import 'package:jobbees_mobile/features/auth/screens/signup_screen.dart';

void main() {
  testWidgets('shows both roles, decide-later, and a disabled CTA', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RoleSelectionScreen()));

    expect(find.text('Get a job done'), findsOneWidget);
    expect(find.text('Earn as a tasker'), findsOneWidget);
    expect(find.text("I'll decide later"), findsOneWidget);
    expect(find.text('Pick one to continue'), findsOneWidget);
  });

  testWidgets('selecting a role relabels the continue CTA', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RoleSelectionScreen()));

    await tester.tap(find.text('Earn as a tasker'));
    await tester.pumpAndSettle();

    expect(find.text('Continue as a tasker'), findsOneWidget);
    expect(find.text('Pick one to continue'), findsNothing);
  });

  testWidgets('continue carries the chosen role into signup', (tester) async {
    final router = GoRouter(
      initialLocation: '/auth/role',
      routes: [
        GoRoute(
          path: '/auth/role',
          builder: (context, state) => const RoleSelectionScreen(),
        ),
        GoRoute(
          path: '/auth/signup',
          builder: (context, state) {
            final role = switch (state.uri.queryParameters['role']) {
              'client' => UserRole.client,
              'tasker' => UserRole.tasker,
              _ => null,
            };
            return SignupScreen(role: role);
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    await tester.tap(find.text('Earn as a tasker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as a tasker'));
    await tester.pumpAndSettle();

    // Landed on signup, carrying the tasker role through.
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Signing up as a tasker'), findsOneWidget);
  });
}
