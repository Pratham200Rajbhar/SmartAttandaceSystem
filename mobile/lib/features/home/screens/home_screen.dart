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
import 'package:smart_attendance_app/shared/widgets/stat_tile.dart';
import 'package:smart_attendance_app/shared/widgets/info_banner.dart';
import 'package:smart_attendance_app/shared/widgets/shimmer_placeholder.dart';
import 'package:smart_attendance_app/shared/widgets/streak_counter.dart';
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
              _WelcomeCard(user: user),
              const SizedBox(height: SasSpacing.md),

              // At-risk attendance warning
              if (overallPct > 0 && overallPct < 75) ...[
                _LowAttendanceWarning(
                  percentage: overallPct,
                  onTap: () => context.go('/analytics'),
                ),
                const SizedBox(height: SasSpacing.sm),
              ],

              // Pending sync indicator
              if (pendingCount > 0) ...[
                _PendingSyncCard(count: pendingCount),
                const SizedBox(height: SasSpacing.sm),
              ],

              // Quick stats row
              if (historyState.data != null) ...[
                const SizedBox(height: SasSpacing.sm),
                _QuickStatsRow(
                  overallPct: overallPct,
                  history: historyState.data!.history,
                  onTapAnalytics: () => context.go('/analytics'),
                ),
              ],

              // Streak counter
              if (historyState.data != null &&
                  calculateStreak(historyState.data!.history) > 0) ...[
                const SizedBox(height: SasSpacing.sm),
                StreakCounter(
                  currentStreak:
                      calculateStreak(historyState.data!.history),
                  highestStreak:
                      calculateHighestStreak(historyState.data!.history),
                  isCompact: true,
                ),
              ],

              const SizedBox(height: SasSpacing.sm),

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
                      fontWeight: FontWeight.w600,
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
  const _WelcomeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                SasColors.accentEmerald.withValues(alpha: 0.2),
                SasColors.accentTeal.withValues(alpha: 0.1),
              ]),
              border: Border.all(
                color: SasColors.accentEmerald.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: SasColors.accentEmerald,
              size: 24,
            ),
          ),
          const SizedBox(width: SasSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    color: SasColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (user?.studentProfile?.firstName != null &&
                          user?.studentProfile?.lastName != null)
                      ? '${user?.studentProfile?.firstName} ${user?.studentProfile?.lastName}'
                      : user?.email ?? 'Student',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SasColors.textPrimary,
                  ),
                ),
                if (user?.studentProfile != null)
                  Text(
                    'Roll No: ${user!.studentProfile!.enrollmentNumber}',
                    style: const TextStyle(
                      color: SasColors.textMuted,
                      fontSize: 12,
                    ),
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

class _PendingSyncCard extends StatelessWidget {
  final int count;
  const _PendingSyncCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: SasColors.info.withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SasColors.info.withValues(alpha: 0.12),
              borderRadius: SasRadius.mdAll,
            ),
            child: const Icon(
              Icons.cloud_sync_rounded,
              size: 20,
              color: SasColors.info,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pending Sync',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$count submission${count == 1 ? '' : 's'} waiting for network',
                  style: const TextStyle(
                    color: SasColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: SasColors.info.withValues(alpha: 0.1),
              borderRadius: SasRadius.xlAll,
              border: Border.all(
                color: SasColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: SasColors.info,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final double overallPct;
  final List<AttendanceHistoryItem> history;
  final VoidCallback onTapAnalytics;

  const _QuickStatsRow({
    required this.overallPct,
    required this.history,
    required this.onTapAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final weekPresent = computeWeekPresent(history);
    final streak = calculateStreak(history);

    return GestureDetector(
      onTap: onTapAnalytics,
      child: Row(
        children: [
          Expanded(
            child: StatTile(
              label: 'Overall',
              value: '${overallPct.toStringAsFixed(0)}%',
              color:
                  overallPct >= 75 ? SasColors.success : SasColors.warning,
              icon: Icons.bar_chart_rounded,
            ),
          ),
          const SizedBox(width: SasSpacing.sm),
          Expanded(
            child: StatTile(
              label: 'This Week',
              value: '$weekPresent',
              color: SasColors.info,
              icon: Icons.calendar_today_rounded,
            ),
          ),
          const SizedBox(width: SasSpacing.sm),
          Expanded(
            child: StatTile(
              label: 'Streak',
              value: '$streak',
              color: SasColors.accentEmerald,
              icon: Icons.local_fire_department_rounded,
            ),
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
