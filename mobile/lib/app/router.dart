// GoRouter configuration with auth-aware redirect guards.
// Tabs: Home | Attendance | Analytics | Profile
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:smart_attendance_app/features/profile/screens/profile_screen.dart';
import 'package:smart_attendance_app/features/settings/screens/goals_screen.dart';
import 'package:smart_attendance_app/features/settings/screens/notification_prefs_screen.dart';
import 'package:smart_attendance_app/features/settings/screens/device_screen.dart';
import 'package:smart_attendance_app/features/settings/screens/help_screen.dart';
import 'package:smart_attendance_app/features/settings/screens/sync_status_screen.dart';
import 'package:smart_attendance_app/features/smart_pass/screens/smart_pass_screen.dart';
import 'package:smart_attendance_app/features/leave/screens/leave_requests_screen.dart';
import 'package:smart_attendance_app/features/leave/screens/leave_history_screen.dart';
import 'package:smart_attendance_app/features/disputes/screens/dispute_submission_screen.dart';
import 'package:smart_attendance_app/shared/widgets/glass_bottom_nav.dart';
import 'package:smart_attendance_app/shared/widgets/glass_app_bar.dart';

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
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register-face', builder: (_, __) => const FaceRegistrationScreen()),

      // Shell route — 4 tabs: Home, Attendance, Analytics, Profile
      ShellRoute(
        builder: (context, state, child) => _ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/attendance',
            pageBuilder: (_, __) => const NoTransitionPage(child: HistoryScreen()),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (_, __) => const NoTransitionPage(child: AnalyticsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, __) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // Standalone routes (no bottom nav)
      GoRoute(
        path: '/verify/:sessionId',
        builder: (context, state) =>
            VerificationScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(path: '/result', builder: (_, __) => const ResultScreen()),

      // Notifications (accessible from profile)
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const _NotificationsPage(),
      ),

      // Flagged detail — receives AttendanceHistoryItem as extra
      GoRoute(
        path: '/flagged/:attendanceId',
        builder: (context, state) {
          final item = state.extra as AttendanceHistoryItem;
          return FlaggedDetailScreen(item: item);
        },
      ),

      // Subject detail
      GoRoute(
        path: '/subject/:classId',
        builder: (context, state) =>
            SubjectDetailScreen(classId: state.pathParameters['classId']!),
      ),

      // Settings sub-screens
      GoRoute(path: '/settings/goals', builder: (_, __) => const GoalsScreen()),
      GoRoute(path: '/settings/notifications', builder: (_, __) => const NotificationPrefsScreen()),
      GoRoute(path: '/settings/device', builder: (_, __) => const DeviceScreen()),
      GoRoute(path: '/settings/help', builder: (_, __) => const HelpScreen()),
      GoRoute(path: '/settings/sync', builder: (_, __) => const SyncStatusScreen()),
      
      // Smart Pass
      GoRoute(path: '/smart-pass', builder: (_, __) => const SmartPassScreen()),
      
      // Leave Management
      GoRoute(path: '/leave/request', builder: (_, __) => const LeaveRequestsScreen()),
      GoRoute(path: '/leave/history', builder: (_, __) => const LeaveHistoryScreen()),
      
      // Dispute Management
      GoRoute(
        path: '/dispute/:attendanceId',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return DisputeSubmissionScreen(
            attendanceId: state.pathParameters['attendanceId']!,
            className: extra['className'] as String,
            subject: extra['subject'] as String,
          );
        },
      ),
    ],
  );
});

class _ShellScaffold extends StatelessWidget {
  final Widget child;
  const _ShellScaffold({required this.child});

  static const _tabPaths = ['/home', '/attendance', '/analytics', '/profile'];

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

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Notifications'),
      body: const NotificationsScreen(),
    );
  }
}
