
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/core/attendance_utils.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/features/history/providers/history_provider.dart';
import 'package:smart_attendance_app/features/settings/providers/preferences_provider.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_app_bar.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final String classId;
  const SubjectDetailScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hState = ref.watch(historyProvider);
    final prefs = ref.watch(preferencesProvider);
    final target = prefs.attendanceTarget;

    final allItems = hState.data?.history ?? [];
    final items =
        allItems.where((h) => h.classId == classId).toList()
          ..sort((a, b) => b.markedAt.compareTo(a.markedAt));

    final subjectName =
        items.isNotEmpty ? items.first.subject : 'Subject';
    final className =
        items.isNotEmpty ? items.first.className : '';

    final total = items.length;
    final present = countPresentOrApproved(items);
    final absent = countAbsent(items);
    final flagged = countFlagged(items);
    final pct = computeSubjectPct(present, total);
    final color = pctColor(pct);

    final needs = computeAttendanceNeeds(
      present: present,
      total: total,
      target: target,
    );
    final canMiss = needs.canMiss;
    final needToAttend = needs.needToAttend;

    return Scaffold(
      appBar: GlassAppBar(title: subjectName),
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subjectName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    if (className.isNotEmpty)
                      Text(className,
                          style: const TextStyle(
                              color: SasColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: _MiniStat(
                                label: 'Present',
                                value: '$present',
                                color: SasColors.success)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _MiniStat(
                                label: 'Absent',
                                value: '$absent',
                                color: SasColors.danger)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _MiniStat(
                                label: 'Flagged',
                                value: '$flagged',
                                color: SasColors.warning)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _MiniStat(
                                label: 'Total',
                                value: '$total',
                                color: SasColors.info)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Attendance',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('${pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        backgroundColor: SasColors.glassBg,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (pct >= target)
                      Text(
                        canMiss > 0
                            ? 'You can miss $canMiss more sessions and stay above ${target.toStringAsFixed(0)}%'
                            : 'You are exactly at your target.',
                        style: const TextStyle(
                            color: SasColors.success, fontSize: 12),
                      )
                    else
                      Text(
                        'Attend $needToAttend more sessions to reach ${target.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: SasColors.warning, fontSize: 12),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (items.isEmpty)
                GlassCard(
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No attendance records for this subject.',
                          style: TextStyle(
                              color: SasColors.textMuted, fontSize: 13)),
                    ),
                  ),
                )
              else ...[
                const Text(
                  'SESSION HISTORY',
                  style: TextStyle(
                    color: SasColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SessionRow(item: item),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final AttendanceHistoryItem item;
  const _SessionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(item.status);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: item.status == 'Flagged'
          ? () => context.push('/flagged/${item.attendanceId}',
              extra: item)
          : null,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, MMM d').format(item.markedAt),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  DateFormat.jm().format(item.markedAt),
                  style: const TextStyle(
                      color: SasColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (item.finalAiScore != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: SasColors.glassBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(item.finalAiScore! * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: SasColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(item.status,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          if (isFlagged(item.status)) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: SasColors.textMuted, size: 16),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          Text(label,
              style: const TextStyle(
                  color: SasColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}
