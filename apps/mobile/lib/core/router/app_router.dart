// ignore_for_file: public_member_api_docs

/// The app router (FW-03).
///
/// Web-friendly URL paths mirror the deep-link surface the mobile cross-cutting
/// work adds in Sprint 2. The clean-URL strategy ([usePathUrlStrategy]) is set
/// in `bootstrap.dart`; here we declare the routes plus the first-run redirect
/// (splash → welcome carousel → home). Auth-driven redirects (CLAUDE.md rule 5)
/// are layered on when the login screen lands later in Sprint 2.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/providers/onboarding_providers.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/welcome_carousel_screen.dart';
import '../../features/shell/screens/placeholder_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects when onboarding state changes (splash finishing, welcome
  // marked seen) WITHOUT rebuilding the GoRouter — rebuilding would drop the
  // navigation stack and browser history.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref
    ..listen(splashCompleteProvider, (_, _) => refresh.value++)
    ..listen(welcomeSeenProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final splashDone = ref.read(splashCompleteProvider);
      final welcomeSeen = ref.read(welcomeSeenProvider);

      // Splash only gates the cold-launch entry; once its branding moment is
      // done, move on to the carousel (first run) or home. Deep links to other
      // routes are never bounced through splash.
      if (loc == '/splash') {
        if (!splashDone) return null;
        return welcomeSeen ? '/' : '/welcome';
      }

      // First-run gate: send users who haven't seen the carousel to it.
      if (!welcomeSeen && loc == '/') return '/welcome';

      // Don't let the carousel reappear once it's been seen.
      if (welcomeSeen && loc == '/welcome') return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeCarouselScreen(),
      ),
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
