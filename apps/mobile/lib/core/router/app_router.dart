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
import '../../features/auth/providers/biometric_providers.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/account_suspended_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/unlock_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/providers/onboarding_providers.dart';
import '../../features/profile/screens/my_profile_screen.dart';
import '../../features/profile/screens/public_tasker_profile_screen.dart';
import '../../features/profile/screens/tasker_profile_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/welcome_carousel_screen.dart';
import '../../features/shell/screens/placeholder_screen.dart';
import '../../features/shell/widgets/scaffold_with_nav_bar.dart';
import '../../features/verification/screens/abn_entry_screen.dart';
import '../../features/verification/screens/become_tasker_screen.dart';
import '../../features/verification/screens/phone_verification_screen.dart';
import '../../features/verification/screens/verification_status_screen.dart';

/// Canonical entry for unauthenticated users (returning users log in; the
/// screen links across to signup). First-run users land on signup straight off
/// the welcome carousel instead — see the redirect below.
const String kSignInRoute = '/auth/login';

/// First-run destination after the welcome carousel: brand-new users go
/// straight to signup. Everyone starts as a client; becoming a tasker is a
/// later in-app upgrade from the profile screen (client note #4).
const String kSignUpRoute = '/auth/signup';

/// Routes reachable while signed out.
const Set<String> _publicRoutes = {
  '/auth/login',
  '/auth/signup',
  '/auth/forgot',
  '/auth/reset',
  '/auth/verify-email',
};

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects when onboarding or auth state changes WITHOUT rebuilding
  // the GoRouter — rebuilding would drop the navigation stack + browser history.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref
    ..listen(splashCompleteProvider, (_, _) => refresh.value++)
    ..listen(welcomeSeenProvider, (_, _) => refresh.value++)
    ..listen(authControllerProvider, (_, _) => refresh.value++)
    ..listen(appLockProvider, (_, _) => refresh.value++);

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
      final suspended = auth.valueOrNull?.isSuspended ?? false;
      final appLocked = ref.read(appLockProvider);

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

      // A suspended session is terminal: pin to the suspended screen until the
      // user logs out (which flips state to signed-out and frees the gate).
      // Non-suspended users never belong on it, so bounce them off.
      if (suspended) return loc == '/suspended' ? null : '/suspended';
      if (loc == '/suspended') return authed ? '/' : kSignInRoute;

      // Biometric app-lock: a returning, authenticated session stays locked
      // until the user passes the biometric prompt (or falls back to password
      // on the unlock screen). Only an authed session can be locked.
      if (authed && appLocked) return loc == '/unlock' ? null : '/unlock';
      if (loc == '/unlock') return authed ? '/' : kSignInRoute;

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
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
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
      GoRoute(
        path: '/suspended',
        builder: (context, state) => const AccountSuspendedScreen(),
      ),
      GoRoute(
        path: '/unlock',
        builder: (context, state) => const UnlockScreen(),
      ),
      // Full-screen flows on the root navigator (cover the bottom nav): the
      // create-a-job flow (launched from the centre FAB) and the public tasker
      // profile preview.
      GoRoute(
        path: '/post',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Post a job', route: '/post'),
      ),
      GoRoute(
        path: '/taskers/:id',
        builder: (context, state) => PublicTaskerProfileScreen(
          taskerId: state.pathParameters['id'] ?? '',
        ),
      ),

      // The authenticated app: a bottom-nav shell (Home / Offers / Post FAB /
      // Messages / Profile). Each tab is a branch with its own back stack, so
      // drilling into a tab keeps the nav bar and the other tabs' state.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          // Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'jobs/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return PlaceholderScreen(
                        title: 'Job $id',
                        route: '/jobs/$id',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Offers — bidding lands in Sprint 4.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/offers',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Offers', route: '/offers'),
              ),
            ],
          ),
          // Messages — messaging lands in Sprint 5.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Messages',
                  route: '/messages',
                ),
              ),
            ],
          ),
          // Profile + its tasker-verification drill-downs (pushed within the
          // tab, so they keep the nav bar and get a back button).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (context, state) => const MyProfileScreen(),
              ),
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
                path: '/profile/tasker',
                builder: (context, state) => const TaskerProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
