
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/core/extensions.dart';
import 'package:smart_attendance_app/core/attendance_utils.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/domain/models/student_stats.dart';
import 'package:smart_attendance_app/features/history/providers/history_provider.dart';
import 'package:smart_attendance_app/features/settings/providers/preferences_provider.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';
import 'package:smart_attendance_app/shared/widgets/legend_dot.dart';
import 'package:smart_attendance_app/shared/widgets/shimmer_placeholder.dart';
import 'package:smart_attendance_app/shared/widgets/stat_tile.dart';
import 'package:smart_attendance_app/features/analytics/providers/leaderboard_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  StudentStats? _stats;

  @override
  void initState() {
    super.initState();
    final currentHistory = ref.read(historyProvider);
    if (currentHistory.data == null) {
      ref.read(historyProvider.notifier).fetch();
    }
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final api = ref.read(studentApiProvider);
      final statsData = await api.getMyStats();
      if (mounted) {
        setState(() {
          _stats = StudentStats.fromJson(statsData);
        });
      }
    } catch (e) {
      // Ignored: failure handled by fallback or cached states
    }
  }

  @override
  Widget build(BuildContext context) {
    final hState = ref.watch(historyProvider);
    final prefs = ref.watch(preferencesProvider);
    final target = prefs.attendanceTarget;

    return AnimatedBackground(
      child: SafeArea(
        child: RefreshIndicator(
          color: SasColors.accentEmerald,
          backgroundColor: SasColors.bgSecondary,
          onRefresh: () async {
            await ref.read(historyProvider.notifier).fetch();
            await _fetchStats();
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart_rounded,
                      color: SasColors.textMuted, size: 20),
                  const SizedBox(width: 8),
                  const Text('Analytics',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 20),

              if (hState.isLoading && hState.data == null)
                const ShimmerPlaceholder(itemCount: 4, itemHeight: 100)
              else if (hState.data == null)
                GlassCard(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const Icon(Icons.cloud_off_rounded,
                          size: 40, color: SasColors.danger),
                      const SizedBox(height: 12),
                      Text(hState.errorMessage ?? 'Failed to load data',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: SasColors.textSecondary, fontSize: 14)),
                      const SizedBox(height: 16),
                    ],
                  ),
                )
              else ...[
                _buildOverallStats(hState.data!, target),
                const SizedBox(height: 16),
                _buildWeeklyChart(hState.data!),
                const SizedBox(height: 16),
                _buildSubjectGoals(hState.data!, target),
                const SizedBox(height: 16),
                _buildStreakCard(hState.data!),
                const SizedBox(height: 16),
                _buildLeaderboardCard(),
                const SizedBox(height: 16),
                _buildSubjectHeatmap(hState.data!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallStats(AttendanceHistoryResponse data, double target) {
    final history = data.history;
    final total = history.length;
    final present = countPresentOrApproved(history);
    final absent = countAbsent(history);
    final flagged = countFlagged(history);
    final pct = data.overallAttendancePercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overview',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: SasColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: StatTile(
                    label: 'Total', value: '$total', color: SasColors.info)),
            const SizedBox(width: 8),
            Expanded(
                child: StatTile(
                    label: 'Present',
                    value: '$present',
                    color: SasColors.success)),
            const SizedBox(width: 8),
            Expanded(
                child: StatTile(
                    label: 'Absent',
                    value: '$absent',
                    color: SasColors.danger)),
            const SizedBox(width: 8),
            Expanded(
                child: StatTile(
                    label: 'Flagged',
                    value: '$flagged',
                    color: SasColors.warning)),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Overall Attendance',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: pctColor(pct),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  backgroundColor: SasColors.glassBg,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(pctColor(pct)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Target: ${target.toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: SasColors.textMuted, fontSize: 12)),
                  if (pct < target)
                    Text(
                      'Need ${(target - pct).toStringAsFixed(1)}% more',
                      style: const TextStyle(
                          color: SasColors.warning, fontSize: 12),
                    )
                  else
                    const Text('Target met ✓',
                        style: TextStyle(
                            color: SasColors.success, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(AttendanceHistoryResponse data) {
    
    final now = DateTime.now();
    final weeks = <String>[];
    final presentCounts = <double>[];
    final totalCounts = <double>[];

    for (int w = 3; w >= 0; w--) {
      final weekStart =
          now.subtract(Duration(days: now.weekday - 1 + w * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final label = DateFormat('MMM d').format(weekStart);
      weeks.add(label);

      final weekItems = data.history.where((h) {
        return h.markedAt.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            h.markedAt.isBefore(weekEnd.add(const Duration(days: 1)));
      }).toList();

      final present = countPresentOrApproved(weekItems).toDouble();
      final total = weekItems.length.toDouble();
      presentCounts.add(present);
      totalCounts.add(total);
    }

    final maxY = totalCounts.fold(0.0, (a, b) => a > b ? a : b);
    final chartMax = maxY < 5 ? 5.0 : maxY + 1;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Attendance (Last 4 Weeks)',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            children: [
              LegendDot(color: SasColors.accentEmerald, label: 'Present', isCircle: false),
              const SizedBox(width: 12),
              LegendDot(color: SasColors.glassBgHover, label: 'Total', isCircle: false),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => SasColors.bgSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? 'Present' : 'Total';
                      return BarTooltipItem(
                        '$label: ${rod.toY.toInt()}',
                        const TextStyle(
                            color: SasColors.textPrimary, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= weeks.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(weeks[idx],
                              style: const TextStyle(
                                  color: SasColors.textMuted,
                                  fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value % 2 != 0) return const SizedBox.shrink();
                        return Text(value.toInt().toString(),
                            style: const TextStyle(
                                color: SasColors.textMuted, fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: SasColors.glassBorder,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(4, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: presentCounts[i],
                        color: SasColors.accentEmerald,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: totalCounts[i],
                        color: SasColors.glassBgHover,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectGoals(AttendanceHistoryResponse data, double target) {
    final subjectStats = _computeSubjectStats(data.history);
    if (subjectStats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Subject Goals',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: SasColors.textSecondary)),
        const SizedBox(height: 8),
        ...subjectStats.entries.map((entry) {
          final stat = entry.value;
          final pct = stat.total > 0
              ? (stat.present / stat.total * 100)
              : 0.0;
          final color = pctColor(pct);

          final needs = computeAttendanceNeeds(
            present: stat.present,
            total: stat.total,
            target: target,
          );
          final canMiss = needs.canMiss;
          final needToAttend = needs.needToAttend;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              onTap: () => context.push('/subject/${entry.key}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stat.subject,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(stat.className,
                                style: const TextStyle(
                                    color: SasColors.textMuted,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      Text('${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      backgroundColor: SasColors.glassBg,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${stat.present}/${stat.total} classes',
                          style: const TextStyle(
                              color: SasColors.textMuted, fontSize: 11)),
                      if (pct >= target)
                        Text(
                          canMiss > 0
                              ? 'Can miss $canMiss more'
                              : 'At target',
                          style: const TextStyle(
                              color: SasColors.success, fontSize: 11),
                        )
                      else
                        Text(
                          'Attend $needToAttend more to reach ${target.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: SasColors.warning, fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLeaderboardCard() {
    final lbState = ref.watch(leaderboardProvider);
    final userPoints = lbState.data?.userPoints ?? 0;
    final userRank = lbState.data?.userRank;

    return GlassCard(
      onTap: () => context.push('/leaderboard'),
      borderColor: SasColors.accentAmber.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SasColors.accentAmber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: SasColors.accentAmber,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leaderboard & Points',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: SasColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userRank != null
                      ? 'Rank: #$userRank · $userPoints pts'
                      : '$userPoints pts · Tap to view leaderboard',
                  style: const TextStyle(
                    fontSize: 13,
                    color: SasColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: SasColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(AttendanceHistoryResponse data) {
    if (_stats != null && _stats!.highestStreak > 0) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        borderColor: SasColors.accentEmerald.withValues(alpha: 0.3),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SasColors.accentEmerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.local_fire_department_rounded,
                  color: SasColors.accentEmerald, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_stats!.highestStreak} session streak',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  Text(
                    'Current: ${_stats!.currentStreak} sessions',
                    style: const TextStyle(
                        color: SasColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              '🔥',
              style: const TextStyle(fontSize: 28),
            ),
          ],
        ),
      );
    }

    final subjectStreaks = <String, int>{};
    final subjectNames = <String, String>{};
    final grouped = <String, List<AttendanceHistoryItem>>{};

    for (final item in data.history) {
      grouped.putIfAbsent(item.classId, () => []).add(item);
      subjectNames[item.classId] = item.subject;
    }

    for (final entry in grouped.entries) {
      final sorted = [...entry.value]
        ..sort((a, b) => b.markedAt.compareTo(a.markedAt));
      int streak = 0;
      for (final item in sorted) {
        if (isPresentOrApproved(item.status)) {
          streak++;
        } else {
          break;
        }
      }
      subjectStreaks[entry.key] = streak;
    }

    final maxEntry = subjectStreaks.entries.fold<MapEntry<String, int>?>(
      null,
      (prev, e) => prev == null || e.value > prev.value ? e : prev,
    );

    if (maxEntry == null || maxEntry.value == 0) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: SasColors.accentEmerald.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SasColors.accentEmerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: SasColors.accentEmerald, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${maxEntry.value} session streak',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  'in ${subjectNames[maxEntry.key] ?? 'a subject'}',
                  style: const TextStyle(
                      color: SasColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '🔥',
            style: const TextStyle(fontSize: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectHeatmap(AttendanceHistoryResponse data) {
    final subjectStats = _computeSubjectStats(data.history);
    if (subjectStats.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final weekLabels = <String>[];
    for (int w = 3; w >= 0; w--) {
      final weekStart =
          now.subtract(Duration(days: now.weekday - 1 + w * 7));
      weekLabels.add(DateFormat('MMM d').format(weekStart));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Subject Heatmap',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: SasColors.textSecondary)),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              
              Row(
                children: [
                  const SizedBox(width: 100),
                  ...weekLabels.map((l) => Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(l,
                                style: const TextStyle(
                                    color: SasColors.textMuted,
                                    fontSize: 9)),
                          ),
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 8),
              ...subjectStats.entries.map((entry) {
                final stat = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          stat.subject.truncate(12),
                          style: const TextStyle(
                              color: SasColors.textSecondary,
                              fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...List.generate(4, (w) {
                        final weekStart = now.subtract(
                            Duration(days: now.weekday - 1 + (3 - w) * 7));
                        final weekEnd =
                            weekStart.add(const Duration(days: 6));
                        final weekItems = stat.items.where((h) {
                          return h.markedAt.isAfter(weekStart
                                  .subtract(const Duration(days: 1))) &&
                              h.markedAt.isBefore(
                                  weekEnd.add(const Duration(days: 1)));
                        }).toList();
                        final wTotal = weekItems.length;
                        final wPresent = countPresentOrApproved(weekItems);
                        final wPct =
                            wTotal > 0 ? wPresent / wTotal : -1.0;

                        Color cellColor;
                        if (wPct < 0) {
                          cellColor = SasColors.glassBg;
                        } else if (wPct >= 0.75) {
                          cellColor =
                              SasColors.success.withValues(alpha: 0.3);
                        } else if (wPct >= 0.5) {
                          cellColor =
                              SasColors.warning.withValues(alpha: 0.3);
                        } else {
                          cellColor =
                              SasColors.danger.withValues(alpha: 0.3);
                        }

                        return Expanded(
                          child: Container(
                            height: 28,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 2),
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: SasColors.glassBorder,
                                  width: 0.5),
                            ),
                            child: wPct >= 0
                                ? Center(
                                    child: Text(
                                      '${(wPct * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                          fontSize: 8,
                                          color: SasColors.textSecondary),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  LegendDot(
                      color: SasColors.success.withValues(alpha: 0.3),
                      label: '≥75%', isCircle: false),
                  const SizedBox(width: 8),
                  LegendDot(
                      color: SasColors.warning.withValues(alpha: 0.3),
                      label: '50–74%', isCircle: false),
                  const SizedBox(width: 8),
                  LegendDot(
                      color: SasColors.danger.withValues(alpha: 0.3),
                      label: '<50%', isCircle: false),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, _SubjectAnalyticsStat> _computeSubjectStats(
      List<AttendanceHistoryItem> history) {
    final map = <String, _SubjectAnalyticsStat>{};
    for (final item in history) {
      final stat = map.putIfAbsent(
        item.classId,
        () => _SubjectAnalyticsStat(
            subject: item.subject, className: item.className),
      );
      stat.total++;
      stat.items.add(item);
      if (isPresentOrApproved(item.status)) {
        stat.present++;
      }
    }
    return map;
  }


}

class _SubjectAnalyticsStat {
  final String subject;
  final String className;
  int total = 0;
  int present = 0;
  final List<AttendanceHistoryItem> items = [];

  _SubjectAnalyticsStat({required this.subject, required this.className});
}

// _StatCard, _LegendDot, _ShimmerAnalytics replaced by shared widgets:
// StatTile, LegendDot, ShimmerPlaceholder from shared/widgets/
