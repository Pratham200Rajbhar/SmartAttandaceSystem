
import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class AtRiskBanner extends StatelessWidget {
  final double attendancePercentage;
  final VoidCallback onTap;

  const AtRiskBanner({
    super.key,
    required this.attendancePercentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    
    if (attendancePercentage >= 75) {
      return const SizedBox.shrink();
    }

    final isCritical = attendancePercentage < 60;
    final color = isCritical ? SasColors.danger : SasColors.warning;
    final icon = isCritical
        ? Icons.error_outline_rounded
        : Icons.warning_amber_rounded;

    return GlassCard(
      borderColor: color.withValues(alpha: 0.5),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCritical ? 'Critical: At-Risk Student' : 'Low Attendance Warning',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCritical
                      ? 'Your attendance is ${attendancePercentage.toStringAsFixed(0)}% — immediate action required!'
                      : 'Your attendance is ${attendancePercentage.toStringAsFixed(0)}% — below the 75% requirement.',
                  style: const TextStyle(
                    color: SasColors.textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ],
      ),
    );
  }
}
