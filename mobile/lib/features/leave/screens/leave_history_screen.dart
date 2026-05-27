
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/core/attendance_constants.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/domain/models/leave_request.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_app_bar.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

final leaveHistoryProvider =
    FutureProvider.autoDispose<List<LeaveRequest>>((ref) async {
  final response = await ref.read(studentApiProvider).getMyLeaves();
  final listResponse = LeaveRequestListResponse.fromJson(response);
  return listResponse.leaves;
});

class LeaveHistoryScreen extends ConsumerWidget {
  const LeaveHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(leaveHistoryProvider);

    return Scaffold(
      appBar: const GlassAppBar(title: 'Leave History'),
      body: AnimatedBackground(
        child: SafeArea(
          child: historyAsync.when(
            data: (leaves) => leaves.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(leaves),
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState(error.toString()),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<LeaveRequest> leaves) {
    
    final sorted = [...leaves]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final pending = leaves.where((l) => l.status == kStatusPending).length;
    final approved = leaves.where((l) => l.status == kStatusApprovedUpper).length;
    final rejected = leaves.where((l) => l.status == kStatusRejected).length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        
        GlassCard(
          child: Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Pending',
                  value: '$pending',
                  color: SasColors.warning,
                  icon: Icons.pending_outlined,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: SasColors.glassBorder,
              ),
              Expanded(
                child: _StatItem(
                  label: 'Approved',
                  value: '$approved',
                  color: SasColors.success,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: SasColors.glassBorder,
              ),
              Expanded(
                child: _StatItem(
                  label: 'Rejected',
                  value: '$rejected',
                  color: SasColors.danger,
                  icon: Icons.cancel_outlined,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'LEAVE REQUESTS',
          style: TextStyle(
            color: SasColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        ...sorted.map((leave) => _LeaveTimelineItem(leave: leave)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Icon(Icons.event_busy_rounded,
                  size: 56, color: SasColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text(
                'No Leave Requests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: SasColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You haven\'t submitted any leave requests yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SasColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: SasColors.glassBg,
        highlightColor: SasColors.glassBgHover,
        child: Column(
          children: List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: SasColors.glassBg,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: GlassCard(
          borderColor: SasColors.danger.withValues(alpha: 0.3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: SasColors.danger),
              const SizedBox(height: 16),
              const Text(
                'Failed to Load',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: SasColors.danger,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SasColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: SasColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _LeaveTimelineItem extends StatelessWidget {
  final LeaveRequest leave;

  const _LeaveTimelineItem({required this.leave});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(leave.status);
    final statusIcon = _getStatusIcon(leave.status);
    final dayCount = leave.endDate.difference(leave.startDate).inDays + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(statusIcon, size: 16, color: statusColor),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: SasColors.glassBorder,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

          Expanded(
            child: GlassCard(
              borderColor: statusColor.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          leave.reason,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          leave.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 12, color: SasColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        '${DateFormat('MMM d').format(leave.startDate)} - ${DateFormat('MMM d, yyyy').format(leave.endDate)}',
                        style: const TextStyle(
                          color: SasColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($dayCount ${dayCount == 1 ? 'day' : 'days'})',
                        style: const TextStyle(
                          color: SasColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (leave.documentUrl != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.link_rounded,
                            size: 12, color: SasColors.info),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Document attached',
                            style: const TextStyle(
                              color: SasColors.info,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (leave.approverNote != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: SasColors.glassBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.person_rounded,
                              size: 14, color: SasColors.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              leave.approverNote!,
                              style: const TextStyle(
                                color: SasColors.textSecondary,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Submitted ${DateFormat('MMM d, yyyy').format(leave.createdAt)}',
                    style: const TextStyle(
                      color: SasColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Color _getStatusColor(String status) {
    switch (status) {
      case kStatusApprovedUpper:
        return SasColors.success;
      case kStatusRejected:
        return SasColors.danger;
      default:
        return SasColors.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case kStatusApprovedUpper:
        return Icons.check_circle_rounded;
      case kStatusRejected:
        return Icons.cancel_rounded;
      default:
        return Icons.pending_rounded;
    }
  }
}
