// ignore_for_file: public_member_api_docs

/// The app router (FW-03).
///
/// Web-friendly URL paths mirror the deep-link surface the mobile cross-cutting
/// work adds in Sprint 2. The clean-URL strategy ([usePathUrlStrategy]) is set
/// in `bootstrap.dart`; here we just declare the routes. Auth-driven redirects
/// (CLAUDE.md rule 5) are wired when the login screen lands in Sprint 2.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/shell/screens/placeholder_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Sign up', route: '/auth/signup'),
      ),
      GoRoute(
        path: '/post',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Post a job', route: '/post'),
      ),
      GoRoute(
        path: '/me',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'My profile', route: '/me'),
      ),
      GoRoute(
        path: '/jobs/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PlaceholderScreen(title: 'Job $id', route: '/jobs/$id');
        },
      ),
    ],
  );
});
