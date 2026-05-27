import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/domain/enums/auth_state.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/features/auth/providers/auth_provider.dart';
import 'package:smart_attendance_app/features/auth/screens/login_screen.dart';
import 'package:smart_attendance_app/features/auth/screens/splash_screen.dart';
import 'package:smart_attendance_app/features/registration/screens/face_registration_screen.dart';
import 'package:smart_attendance_app/features/home/screens/home_screen.dart';
import 'package:smart_attendance_app/features/attendance/screens/verification_screen.dart';

import 'package:smart_attendance_app/features/attendance/screens/result_screen.dart';
import 'package:smart_attendance_app/features/attendance/screens/flagged_detail_screen.dart';
import 'package:smart_attendance_app/features/history/screens/history_screen.dart';
import 'package:smart_attendance_app/features/history/screens/subject_detail_screen.dart';
import 'package:smart_attendance_app/features/notifications/screens/notifications_screen.dart';
import 'package:smart_attendance_app/features/analytics/screens/analytics_screen.dart';
import 'package:smart_attendance_app/features/analytics/screens/leaderboard_screen.dart';
import 'package:smart_attendance_app/features/profile/screens/profile_screen.dart';
import 'package:smart_attendance_app/features/settings/screens/goals_screen.dart';
import 'package:smart_attendance_app/features/settings/screens/notification_prefs_screen.dart';
import 'package:smart_attendance_app/features/settings/screens/help_screen.dart';
import 'package:smart_attendance_app/features/settings/screens/sync_status_screen.dart';
import 'package:smart_attendance_app/features/smart_pass/screens/smart_pass_screen.dart';
import 'package:smart_attendance_app/features/leave/screens/leave_requests_screen.dart';
import 'package:smart_attendance_app/features/leave/screens/leave_history_screen.dart';
import 'package:smart_attendance_app/shared/widgets/glass_bottom_nav.dart';

/// Notifies GoRouter when auth state changes to trigger redirect evaluation.
final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  final notifier = RouterNotifier();
  ref.listen(authProvider, (previous, next) {
    if (previous?.status != next.status) {
      notifier.notify();
    }
  });
  return notifier;
});

class RouterNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final path = state.uri.path;
      final authState = ref.read(authProvider);
      final status = authState.status;

      if (path == '/splash') {
        if (status == AuthStatus.loading) return null;
        if (status == AuthStatus.unauthenticated) return '/login';
        if (status == AuthStatus.registrationRequired) return '/register-face';
        if (status == AuthStatus.authenticated) return '/home';
        return null;
      }
      if (path == '/login') {
        if (status == AuthStatus.authenticated) return '/home';
        if (status == AuthStatus.registrationRequired) return '/register-face';
        return null;
      }
      if (path == '/register-face') {
        if (status == AuthStatus.authenticated) return '/home';
        if (status == AuthStatus.unauthenticated) return '/login';
        return null;
      }
      if (status == AuthStatus.unauthenticated) return '/login';
      if (status == AuthStatus.registrationRequired) return '/register-face';
      return null;
    },
    routes: [
      // --- Auth flow (no bottom nav) ---
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/register-face',
        builder: (_, __) => const FaceRegistrationScreen(),
      ),

      // --- Main app shell (bottom nav) ---
      ShellRoute(
        builder: (context, state, child) => _ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: HistoryScreen()),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: AnalyticsScreen()),
          ),
          GoRoute(
            path: '/more',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // --- Stack routes with slide transitions ---
      GoRoute(
        path: '/verify/:sessionId',
        pageBuilder: (context, state) => _slideUpPage(
          key: state.pageKey,
          child: VerificationScreen(
            sessionId: state.pathParameters['sessionId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/result',
        pageBuilder: (_, state) => _slideUpPage(
          key: state.pageKey,
          child: const ResultScreen(),
        ),
      ),

      GoRoute(
        path: '/notifications',
        pageBuilder: (_, state) => _slideRightPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
        ),
      ),


      GoRoute(
        path: '/flagged/:attendanceId',
        pageBuilder: (context, state) {
          final attendanceId = state.pathParameters['attendanceId']!;
          final item = state.extra as AttendanceHistoryItem?;
          return _slideRightPage(
            key: state.pageKey,
            child: FlaggedDetailScreen(
              item: item,
              attendanceId: attendanceId,
            ),
          );
        },
      ),

      GoRoute(
        path: '/leaderboard',
        pageBuilder: (_, state) => _slideRightPage(
          key: state.pageKey,
          child: const LeaderboardScreen(),
        ),
      ),

      GoRoute(
        path: '/subject/:classId',
        pageBuilder: (_, state) => _slideRightPage(
          key: state.pageKey,
          child: SubjectDetailScreen(
            classId: state.pathParameters['classId']!,
          ),
        ),
      ),

      // --- Settings stack ---
      GoRoute(
        path: '/settings/goals',
        pageBuilder: (_, state) => _slideRightPage(
          key: state.pageKey,
          child: const GoalsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/notifications',
        pageBuilder: (_, state) => _slideRightPage(
          key: state.pageKey,
          child: const NotificationPrefsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/help',
        pageBuilder: (_, state) => _slideRightPage(
          key: state.pageKey,
          child: const HelpScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/sync',
        pageBuilder: (_, state) => _slideRightPage(
          key: state.pageKey,
          child: const SyncStatusScreen(),
        ),
      ),

      // --- Feature stack routes ---
      GoRoute(
        path: '/smart-pass',
        pageBuilder: (_, state) => _slideUpPage(
          key: state.pageKey,
          child: const SmartPassScreen(),
        ),
      ),
      GoRoute(
        path: '/leave/request',
        pageBuilder: (_, state) => _slideUpPage(
          key: state.pageKey,
          child: const LeaveRequestsScreen(),
        ),
      ),
      GoRoute(
        path: '/leave/history',
        pageBuilder: (_, state) => _slideRightPage(
          key: state.pageKey,
          child: const LeaveHistoryScreen(),
        ),
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Transition helpers
// ---------------------------------------------------------------------------

/// Slide-up transition for modal-style screens (verification, leave request, smart pass).
CustomTransitionPage<void> _slideUpPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: SasDurations.slow,
    reverseTransitionDuration: SasDurations.slow,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

/// Slide-right transition for detail/settings screens.
CustomTransitionPage<void> _slideRightPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: SasDurations.slow,
    reverseTransitionDuration: SasDurations.slow,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.25, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Shell scaffold
// ---------------------------------------------------------------------------

class _ShellScaffold extends StatelessWidget {
  final Widget child;
  const _ShellScaffold({required this.child});

  static const _tabPaths = ['/home', '/history', '/analytics', '/more'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _tabPaths.indexOf(location).clamp(0, 3);

    return Scaffold(
      body: child,
      bottomNavigationBar: GlassBottomNav(
        currentIndex: currentIndex,
        onTap: (index) => context.go(_tabPaths[index]),
      ),
    );
  }
}
