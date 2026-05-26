
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/core/extensions.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/features/auth/providers/auth_provider.dart';
import 'package:smart_attendance_app/features/home/providers/session_provider.dart';
import 'package:smart_attendance_app/features/history/providers/history_provider.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';
import 'package:smart_attendance_app/shared/widgets/at_risk_banner.dart';
import 'package:smart_attendance_app/shared/widgets/streak_counter.dart';

import 'package:smart_attendance_app/data/local/pending_count_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
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
    final rawPct = historyState.data?.overallAttendancePercentage ?? 100;
    final overallPct = (rawPct.isNaN || rawPct.isInfinite) ? 100.0 : rawPct.toDouble();

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
            padding: const EdgeInsets.all(20),
            children: [
              
              GlassCard(
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
                            color:
                                SasColors.accentEmerald.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: SasColors.accentEmerald, size: 24),
                    ),
                    const SizedBox(width: 16),
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
                            (user?.studentProfile?.firstName != null && user?.studentProfile?.lastName != null) 
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
                                  color: SasColors.textMuted, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              AtRiskBanner(
                attendancePercentage: overallPct,
                onTap: () => context.go('/analytics'),
              ),
              if (overallPct < 75) const SizedBox(height: 8),

              if (overallPct >= 60 && overallPct < 75 && historyState.data != null) ...[
                GlassCard(
                  borderColor: SasColors.warning.withValues(alpha: 0.5),
                  onTap: () => context.go('/analytics'),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: SasColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            size: 20, color: SasColors.warning),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Low Attendance Warning',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: SasColors.warning)),
                            Text(
                              'Your attendance is ${overallPct.toStringAsFixed(0)}% — below the 75% requirement.',
                              style: const TextStyle(
                                  color: SasColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: SasColors.warning, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              if (pendingCount > 0) ...[
                GlassCard(
                  borderColor: SasColors.info.withValues(alpha: 0.4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: SasColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded,
                            size: 20, color: SasColors.info),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pending Sync',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(
                              '$pendingCount submission${pendingCount == 1 ? '' : 's'} waiting for network',
                              style: const TextStyle(
                                  color: SasColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: SasColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: SasColors.info.withValues(alpha: 0.3)),
                        ),
                        child: Text('$pendingCount',
                            style: const TextStyle(
                                color: SasColors.info,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              if (historyState.data != null) ...[
                const SizedBox(height: 8),
                _QuickStatsRow(
                  overallPct: overallPct,
                  history: historyState.data!.history,
                  onTapAnalytics: () => context.go('/analytics'),
                ),
              ],

              if (historyState.data != null && _calculateStreak(historyState.data!.history) > 0) ...[
                const SizedBox(height: 8),
                StreakCounter(
                  currentStreak: _calculateStreak(historyState.data!.history),
                  highestStreak: _calculateHighestStreak(historyState.data!.history), 
                  isCompact: true,
                ),
              ],

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      color: SasColors.textMuted, size: 18),
                  const SizedBox(width: 8),
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
                        color: SasColors.textMuted, fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (sessionState.errorMessage != null &&
                  sessionState.sessions.isEmpty) ...[
                _ErrorBanner(
                  message: sessionState.errorMessage!,
                  onRetry: () =>
                      ref.read(sessionProvider.notifier).fetchSessions(),
                ),
              ] else if (sessionState.isLoading &&
                  sessionState.sessions.isEmpty)
                const _ShimmerLoadingPlaceholder()
              else if (sessionState.sessions.isEmpty)
                const _EmptyState()
              else
                ...sessionState.sessions
                    .map((session) => _ClassCard(
                          session: session,
                          isMarked: sessionState.markedSessionIds
                              .contains(session.sessionId),
                        )),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateStreak(List<AttendanceHistoryItem> history) {
    if (history.isEmpty) return 0;
    final sorted = [...history]..sort((a, b) => b.markedAt.compareTo(a.markedAt));
    int streak = 0;
    for (final item in sorted) {
      if (item.status == 'Present' || item.status == 'Approved') {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int _calculateHighestStreak(List<AttendanceHistoryItem> history) {
    if (history.isEmpty) return 0;
    final sorted = [...history]..sort((a, b) => a.markedAt.compareTo(b.markedAt));
    int maxStreak = 0;
    int currentStreak = 0;
    for (final item in sorted) {
      if (item.status == 'Present' || item.status == 'Approved') {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }
    return maxStreak;
  }
}

class _ClassCard extends StatefulWidget {
  final ClassSession session;
  final bool isMarked;
  const _ClassCard({required this.session, required this.isMarked});

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard> {
  Timer? _countdownTimer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(_ClassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.session.sessionEndTime != oldWidget.session.sessionEndTime) {
      _countdownTimer?.cancel();
      _startCountdown();
    }
  }

  void _startCountdown() {
    final endTime = widget.session.sessionEndTime;
    if (endTime == null || !widget.session.isActive) return;

    _updateRemaining(endTime);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining(endTime);
    });
  }

  void _updateRemaining(DateTime endTime) {
    final diff = endTime.difference(DateTime.now());
    if (mounted) {
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    }
    if (diff.isNegative) {
      _countdownTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool get _isWindowClosed => _remaining != null && _remaining == Duration.zero;

  bool get _canMark =>
      widget.session.isActive &&
      widget.session.sessionId != null &&
      !widget.isMarked &&
      !_isWindowClosed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderColor: widget.session.isActive
            ? SasColors.accentEmerald.withValues(alpha: 0.4)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.session.isActive
                        ? SasColors.accentEmerald.withValues(alpha: 0.15)
                        : SasColors.glassBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    size: 20,
                    color: widget.session.isActive
                        ? SasColors.accentEmerald
                        : SasColors.textMuted,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.session.className,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(widget.session.subject,
                          style: const TextStyle(
                              color: SasColors.textMuted, fontSize: 13)),
                      Text(widget.session.teacherName,
                          style: const TextStyle(
                              color: SasColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                if (widget.session.isActive) ...[
                  if (widget.isMarked)
                    _StatusChip(label: 'SUBMITTED', color: SasColors.success)
                  else if (_isWindowClosed)
                    _StatusChip(label: 'CLOSED', color: SasColors.danger)
                  else
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: SasColors.accentEmerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                SasColors.accentEmerald.withValues(alpha: 0.3)),
                      ),
                      child: const Text('LIVE',
                          style: TextStyle(
                              color: SasColors.accentEmerald,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ],
            ),
            
            if (widget.session.isActive && _remaining != null && !_isWindowClosed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 14, color: SasColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${_remaining!.inMinutes}:${(_remaining!.inSeconds % 60).toString().padLeft(2, '0')} remaining',
                    style: TextStyle(
                      color: _remaining!.inMinutes < 2
                          ? SasColors.warning
                          : SasColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (_canMark) ...[
              const SizedBox(height: 16),
              GlassButton(
                label: 'Mark Attendance',
                isExpanded: true,
                icon: Icons.fingerprint_rounded,
                onPressed: () => context.push('/verify/${widget.session.sessionId}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: SasColors.danger.withValues(alpha: 0.3),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Icon(Icons.wifi_off_rounded, size: 40, color: SasColors.danger),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: SasColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          GlassButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ShimmerLoadingPlaceholder extends StatelessWidget {
  const _ShimmerLoadingPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: SasColors.glassBg,
      highlightColor: SasColors.glassBgHover,
      child: Column(
        children: List.generate(
            3,
            (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: SasColors.glassBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                )),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Icon(Icons.event_busy_rounded,
              size: 48, color: SasColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text('No classes today',
              style: TextStyle(
                  color: SasColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Check back when your schedule is updated.',
              style: TextStyle(color: SasColors.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
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
    
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekItems = history.where((h) =>
        h.markedAt.isAfter(weekStart.subtract(const Duration(days: 1)))).toList();
    final weekPresent = weekItems
        .where((h) => h.status == 'Present' || h.status == 'Approved')
        .length;

    final sorted = [...history]..sort((a, b) => b.markedAt.compareTo(a.markedAt));
    int streak = 0;
    for (final item in sorted) {
      if (item.status == 'Present' || item.status == 'Approved') {
        streak++;
      } else {
        break;
      }
    }

    return GestureDetector(
      onTap: onTapAnalytics,
      child: Row(
        children: [
          Expanded(child: _QuickStat(
            label: 'Overall',
            value: '${overallPct.toStringAsFixed(0)}%',
            color: overallPct >= 75 ? SasColors.success : SasColors.warning,
            icon: Icons.bar_chart_rounded,
          )),
          const SizedBox(width: 8),
          Expanded(child: _QuickStat(
            label: 'This Week',
            value: '$weekPresent',
            color: SasColors.info,
            icon: Icons.calendar_today_rounded,
          )),
          const SizedBox(width: 8),
          Expanded(child: _QuickStat(
            label: 'Streak',
            value: '$streak',
            color: SasColors.accentEmerald,
            icon: Icons.local_fire_department_rounded,
          )),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _QuickStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
          Text(label, style: const TextStyle(color: SasColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}
