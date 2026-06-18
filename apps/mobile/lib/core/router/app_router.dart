// ignore_for_file: public_member_api_docs

/// The app router (FW-03).
///
/// Web-friendly URL paths mirror the deep-link surface the mobile cross-cutting
/// work adds in Sprint 2. The clean-URL strategy ([usePathUrlStrategy]) is set
/// in `bootstrap.dart`; here we declare the routes plus the redirect gate that
/// sequences cold launch: splash → (first run) welcome carousel → auth → home.
///
/// Navigation is state-driven (CLAUDE.md rule 5): screens flip onboarding/auth
/// state and this redirect reacts, rather than pushing routes from buttons.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_controller.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/providers/onboarding_providers.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/welcome_carousel_screen.dart';
import '../../features/shell/screens/placeholder_screen.dart';

/// Canonical entry for unauthenticated users (returning users log in; the
/// screen links across to signup). First-run users land on signup straight off
/// the welcome carousel instead — see the redirect below.
const String kSignInRoute = '/auth/login';

/// First-run destination after the welcome carousel (brand-new users sign up).
const String kSignUpRoute = '/auth/signup';

/// Routes reachable while signed out.
const Set<String> _publicRoutes = {'/auth/login', '/auth/signup'};

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects when onboarding or auth state changes WITHOUT rebuilding
  // the GoRouter — rebuilding would drop the navigation stack + browser history.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref
    ..listen(splashCompleteProvider, (_, _) => refresh.value++)
    ..listen(welcomeSeenProvider, (_, _) => refresh.value++)
    ..listen(authControllerProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final splashDone = ref.read(splashCompleteProvider);
      final welcomeSeen = ref.read(welcomeSeenProvider);
      final auth = ref.read(authControllerProvider);
      final restoring = auth.isLoading;
      final authed = auth.valueOrNull != null;

      // Splash gates only the cold-launch entry, and holds until BOTH the
      // branding moment and the session-restore probe finish — so we route
      // straight to the right place without an auth→home flash. Deep links to
      // other routes are never bounced through splash.
      if (loc == '/splash') {
        if (!splashDone || restoring) return null;
        if (!welcomeSeen) return '/welcome';
        return authed ? '/' : kSignInRoute;
      }

      // Hold routing decisions until the session-restore probe settles.
      if (restoring) return null;

      // First-run carousel → sign up (brand-new users); returning users log in.
      if (!welcomeSeen && loc != '/welcome') return '/welcome';
      if (welcomeSeen && loc == '/welcome') {
        return authed ? '/' : kSignUpRoute;
      }

      // Auth gate: protected routes require a session; auth routes bounce home
      // once signed in.
      final isPublic = _publicRoutes.contains(loc);
      if (!authed && !isPublic) return kSignInRoute;
      if (authed && isPublic) return '/';

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
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
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
