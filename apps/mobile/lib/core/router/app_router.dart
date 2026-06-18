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

import '../../features/auth/models/auth_models.dart';
import '../../features/auth/providers/auth_controller.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/providers/onboarding_providers.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/welcome_carousel_screen.dart';
import '../../features/shell/screens/placeholder_screen.dart';
import '../../features/verification/screens/abn_entry_screen.dart';
import '../../features/verification/screens/become_tasker_screen.dart';
import '../../features/verification/screens/phone_verification_screen.dart';
import '../../features/verification/screens/verification_status_screen.dart';

/// Canonical entry for unauthenticated users (returning users log in; the
/// screen links across to signup). First-run users land on signup straight off
/// the welcome carousel instead — see the redirect below.
const String kSignInRoute = '/auth/login';

/// First-run destination after the welcome carousel: brand-new users pick a
/// role, which carries into signup.
const String kSignUpRoute = '/auth/role';

/// Routes reachable while signed out.
const Set<String> _publicRoutes = {
  '/auth/login',
  '/auth/role',
  '/auth/signup',
  '/auth/forgot',
  '/auth/reset',
  '/auth/verify-email',
};

/// Maps the `?role=` signup query param to a [UserRole] (absent → decide later).
UserRole? _roleFromQuery(String? value) => switch (value) {
  'client' => UserRole.client,
  'tasker' => UserRole.tasker,
  _ => null,
};

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

      // First-run: the welcome carousel comes before everything (including the
      // auth gate). Pin to /welcome until it's seen — but don't fight once we're
      // already there, or it loops against the auth gate below.
      if (!welcomeSeen) {
        return loc == '/welcome' ? null : '/welcome';
      }

      // Seen users never sit on the carousel.
      if (loc == '/welcome') {
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
        path: '/auth/role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => SignupScreen(
          role: _roleFromQuery(state.uri.queryParameters['role']),
        ),
      ),
      GoRoute(
        path: '/auth/forgot',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/reset',
        builder: (context, state) =>
            ResetPasswordScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: '/auth/verify-email',
        builder: (context, state) =>
            VerifyEmailScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/verify',
        builder: (context, state) => const VerificationStatusScreen(),
      ),
      GoRoute(
        path: '/verify/abn',
        builder: (context, state) => const AbnEntryScreen(),
      ),
      GoRoute(
        path: '/verify/phone',
        builder: (context, state) => const PhoneVerificationScreen(),
      ),
      GoRoute(
        path: '/become-tasker',
        builder: (context, state) => const BecomeTaskerScreen(),
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
