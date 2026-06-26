import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/core/network/error_mapper.dart';
import 'package:jobbees_mobile/features/profile/data/profile_repository.dart';
import 'package:jobbees_mobile/features/profile/models/tasker_profile.dart';
import 'package:jobbees_mobile/features/profile/providers/profile_providers.dart';
import 'package:jobbees_mobile/features/profile/screens/tasker_profile_screen.dart';

class _FakeRepo extends ProfileRepository {
  _FakeRepo(this._profile, {this.updateError})
    : super(Dio(), newIdempotencyKey: () => 'k');

  final TaskerProfile _profile;
  final Object? updateError;
  Map<String, dynamic>? lastUpdate;

  @override
  Future<TaskerProfile> fetch() async => _profile;

  @override
  Future<TaskerProfile> update({
    String? bio,
    int? hourlyRateCents,
    List<String>? skills,
  }) async {
    if (updateError != null) throw updateError!;
    lastUpdate = {
      'bio': bio,
      'hourlyRateCents': hourlyRateCents,
      'skills': skills,
    };
    return TaskerProfile(
      bio: bio,
      hourlyRateCents: hourlyRateCents,
      skills: skills ?? const [],
    );
  }
}

Future<void> _pump(WidgetTester tester, _FakeRepo repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: TaskerProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('loads and shows the existing skills', (tester) async {
    await _pump(
      tester,
      _FakeRepo(
        const TaskerProfile(
          bio: 'Handy',
          hourlyRateCents: 8500,
          skills: ['plumbing'],
        ),
      ),
    );

    expect(find.text('plumbing'), findsOneWidget);
  });

  testWidgets('edits fields, adds a skill, and saves', (tester) async {
    final repo = _FakeRepo(
      const TaskerProfile(hourlyRateCents: null, skills: ['plumbing']),
    );
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField).at(0), 'New bio'); // about
    await tester.enterText(find.byType(TextField).at(1), '90'); // rate
    await tester.enterText(find.byType(TextField).at(2), 'tiling'); // skill
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(repo.lastUpdate!['bio'], 'New bio');
    expect(repo.lastUpdate!['hourlyRateCents'], 9000); // dollars → cents
    expect(repo.lastUpdate!['skills'], ['plumbing', 'tiling']);
    expect(find.text('Profile saved'), findsOneWidget); // snackbar
  });

  testWidgets('flags an invalid rate and focuses the rate field', (
    tester,
  ) async {
    final repo = _FakeRepo(const TaskerProfile(skills: []));
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField).at(1), 'abc'); // bad rate
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid amount'), findsOneWidget);
    expect(repo.lastUpdate, isNull); // never reached the server
    final rate = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(rate.focusNode?.hasFocus, isTrue);
  });

  testWidgets('shows the error banner when saving fails', (tester) async {
    final repo = _FakeRepo(
      const TaskerProfile(skills: []),
      updateError: const AppError('Could not save'),
    );
    await _pump(tester, repo);

    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('Could not save'), findsOneWidget);
  });
}
