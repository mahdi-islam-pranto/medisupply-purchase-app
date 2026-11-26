import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_controller.dart';
import '../features/approved/presentation/approved_day_screen.dart';
import '../features/approved/presentation/approved_range_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/quote/presentation/quote_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import 'app_shell.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge Riverpod → Listenable so go_router re-runs `redirect`
  // whenever the user signs in or out (including a 401 from the server).
  final session = ValueNotifier<SessionState>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => session.value = next);
  ref.onDispose(session.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: session,
    redirect: (context, state) {
      final status = session.value.status;
      final at = state.matchedLocation;

      switch (status) {
        case SessionStatus.unknown:
          return at == Routes.splash ? null : Routes.splash;
        case SessionStatus.signedOut:
          return at == Routes.signIn ? null : Routes.signIn;
        case SessionStatus.signedIn:
          return (at == Routes.signIn || at == Routes.splash)
              ? Routes.home
              : null;
      }
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          _tab(Routes.home, const HomeScreen()),
          _tab(Routes.quote, const QuoteScreen()),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.history,
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: 'approved',
                    builder: (context, state) => ApprovedDayScreen(
                      date: state.uri.queryParameters['date'],
                    ),
                  ),
                  GoRoute(
                    path: 'approved-range',
                    builder: (context, state) => const ApprovedRangeScreen(),
                  ),
                ],
              ),
            ],
          ),
          _tab(Routes.reports, const ReportsScreen()),
          _tab(Routes.profile, const ProfileScreen()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _tab(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);
