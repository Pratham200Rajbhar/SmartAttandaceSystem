import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/core/extensions.dart';
import 'package:smart_attendance_app/core/attendance_utils.dart';
import 'package:smart_attendance_app/features/auth/providers/auth_provider.dart';
import 'package:smart_attendance_app/features/home/providers/session_provider.dart';
import 'package:smart_attendance_app/features/history/providers/history_provider.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/features/home/widgets/class_session_card.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';
import 'package:smart_attendance_app/shared/widgets/info_banner.dart';
import 'package:smart_attendance_app/shared/widgets/shimmer_placeholder.dart';
import 'package:smart_attendance_app/data/local/pending_count_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(sessionProvider.notifier).startPolling();
    ref.read(historyProvider.notifier).fetch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(sessionProvider.notifier).stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      ref.read(sessionProvider.notifier).stopPolling();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(sessionProvider.notifier).startPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final sessionState = ref.watch(sessionProvider);
    final pendingCount = ref.watch(pendingCountProvider);
    final historyState = ref.watch(historyProvider);
    final rawPct = historyState.data?.overallAttendancePercentage ?? 0;
    final overallPct =
        (rawPct.isNaN || rawPct.isInfinite) ? 0.0 : rawPct.toDouble();

    return AnimatedBackground(
      child: SafeArea(
        child: RefreshIndicator(
          color: SasColors.accentEmerald,
          backgroundColor: SasColors.bgSecondary,
          onRefresh: () async {
            await ref.read(sessionProvider.notifier).fetchSessions();
            await ref.read(historyProvider.notifier).fetch();
          },
          child: ListView(
            padding: SasSpacing.screenPadding,
            children: [
              // Welcome card
              _WelcomeCard(user: user, pendingCount: pendingCount),
              const SizedBox(height: SasSpacing.md),

              // At-risk attendance warning
              if (overallPct > 0 && overallPct < 75) ...[
                _LowAttendanceWarning(
                  percentage: overallPct,
                  onTap: () => context.go('/analytics'),
                ),
                const SizedBox(height: SasSpacing.sm),
              ],

              // Health & Attendance Dashboard Card
              if (historyState.data != null) ...[
                const SizedBox(height: SasSpacing.sm),
                _AttendanceOverviewCard(
                  overallPct: overallPct,
                  history: historyState.data!.history,
                  highestStreak:
                      calculateHighestStreak(historyState.data!.history),
                  onTapAnalytics: () => context.go('/analytics'),
                ),
              ],

              const SizedBox(height: SasSpacing.lg),

              // Today's classes header
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: SasColors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: SasSpacing.sm),
                  const Text(
                    "Today's Classes",
                    style: TextStyle(
                      color: SasColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: SasSpacing.xs),
                  if (sessionState.sessions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: SasColors.accentEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${sessionState.sessions.length}',
                        style: const TextStyle(
                          color: SasColors.accentEmerald,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    DateTime.now().shortDate,
                    style: const TextStyle(
                      color: SasColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: SasSpacing.md),

              // Session list
              if (sessionState.errorMessage != null &&
                  sessionState.sessions.isEmpty)
                InfoBanner(
                  message: sessionState.errorMessage!,
                  severity: BannerSeverity.danger,
                  customIcon: Icons.wifi_off_rounded,
                  actionLabel: 'Retry',
                  onAction: () =>
                      ref.read(sessionProvider.notifier).fetchSessions(),
                )
              else if (sessionState.isLoading &&
                  sessionState.sessions.isEmpty)
                const ShimmerPlaceholder()
              else if (sessionState.sessions.isEmpty)
                const _EmptyClassesState()
              else
                ...sessionState.sessions.map(
                  (session) => ClassSessionCard(
                    session: session,
                    isMarked: sessionState.markedSessionIds
                        .contains(session.sessionId),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets (small, non-reusable, specific to HomeScreen)
// ---------------------------------------------------------------------------

class _WelcomeCard extends StatelessWidget {
  final dynamic user;
  final int pendingCount;
  const _WelcomeCard({required this.user, required this.pendingCount});

  String _getInitials() {
    if (user?.studentProfile?.firstName != null &&
        user?.studentProfile?.lastName != null) {
      final String first = user.studentProfile.firstName;
      final String last = user.studentProfile.lastName;
      if (first.isNotEmpty && last.isNotEmpty) {
        return '${first[0]}${last[0]}'.toUpperCase();
      }
    }
    final String? email = user?.email;
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'S';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return 'Good Morning 🌅';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon ☀️';
    } else {
      return 'Good Evening 🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (user?.studentProfile?.firstName != null &&
            user?.studentProfile?.lastName != null)
        ? '${user?.studentProfile?.firstName} ${user?.studentProfile?.lastName}'
        : user?.email ?? 'Student';
    final enrollmentNumber = user?.studentProfile?.enrollmentNumber ?? '';

    return Row(
      children: [
        // Glowing Avatar Ring
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SasColors.accentEmerald,
                SasColors.accentTeal,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: SasColors.accentEmerald.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: SasColors.accentEmerald.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              _getInitials(),
              style: const TextStyle(
                color: SasColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: SasSpacing.md),
        // Greeting and Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  color: SasColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: SasColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              if (enrollmentNumber.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SasColors.glassBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: SasColors.glassBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        color: SasColors.accentTeal,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        enrollmentNumber,
                        style: const TextStyle(
                          color: SasColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: SasSpacing.sm),
        // Cloud Sync Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: pendingCount > 0
                ? SasColors.warning.withValues(alpha: 0.12)
                : SasColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: pendingCount > 0
                  ? SasColors.warning.withValues(alpha: 0.3)
                  : SasColors.success.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pendingCount > 0
                    ? Icons.sync_problem_rounded
                    : Icons.cloud_done_rounded,
                color: pendingCount > 0 ? SasColors.warning : SasColors.success,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                pendingCount > 0 ? '$pendingCount pending' : 'Synced',
                style: TextStyle(
                  color: pendingCount > 0 ? SasColors.warning : SasColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendanceOverviewCard extends StatelessWidget {
  final double overallPct;
  final List<AttendanceHistoryItem> history;
  final int highestStreak;
  final VoidCallback onTapAnalytics;

  const _AttendanceOverviewCard({
    required this.overallPct,
    required this.history,
    required this.highestStreak,
    required this.onTapAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final weekPresent = computeWeekPresent(history);
    final streak = calculateStreak(history);

    return GlassCard(
      onTap: onTapAnalytics,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Circular gauge
          Column(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: overallPct / 100.0,
                        strokeWidth: 7,
                        backgroundColor: SasColors.glassBorder,
                        color: overallPct >= 75
                            ? SasColors.success
                            : SasColors.warning,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${overallPct.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: SasColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Attendance',
                          style: TextStyle(
                            fontSize: 8,
                            color: SasColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (overallPct >= 75 ? SasColors.success : SasColors.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  overallPct >= 75 ? 'Good Standing' : 'Below 75%',
                  style: TextStyle(
                    color: overallPct >= 75 ? SasColors.success : SasColors.warning,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          // Divider
          Container(
            height: 90,
            width: 1,
            color: SasColors.glassBorder,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // Stats column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Streak item
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SasColors.warning.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🔥', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$streak Day Streak',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: SasColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Best: $highestStreak days',
                            style: const TextStyle(
                              color: SasColors.textMuted,
                              fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
                const SizedBox(height: 14),
                // Weekly classes item
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SasColors.info.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: SasColors.info,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$weekPresent Classes',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: SasColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Attended this week',
                            style: TextStyle(
                              color: SasColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LowAttendanceWarning extends StatelessWidget {
  final double percentage;
  final VoidCallback onTap;
  const _LowAttendanceWarning({
    required this.percentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: SasColors.warning.withValues(alpha: 0.5),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SasColors.warning.withValues(alpha: 0.12),
              borderRadius: SasRadius.mdAll,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: SasColors.warning,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Low Attendance Warning',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: SasColors.warning,
                  ),
                ),
                Text(
                  'Your attendance is ${percentage.toStringAsFixed(0)}% — below the 75% requirement.',
                  style: const TextStyle(
                    color: SasColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: SasColors.warning,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _EmptyClassesState extends StatelessWidget {
  const _EmptyClassesState();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: SasSpacing.lg),
          Icon(
            Icons.event_busy_rounded,
            size: 48,
            color: SasColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: SasSpacing.md),
          const Text(
            'No classes today',
            style: TextStyle(
              color: SasColors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SasSpacing.xs),
          const Text(
            'Check back when your schedule is updated.',
            style: TextStyle(color: SasColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: SasSpacing.lg),
        ],
      ),
    );
  }
}
