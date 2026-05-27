import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';

/// Unified chip widget replacing duplicated _StatusChip, _FilterChip variants
/// across home, history, and profile screens.
///
/// [variant] controls visual style:
/// - [StatusChipVariant.filled] — colored background with matching border
/// - [StatusChipVariant.outlined] — transparent background, colored border only
enum StatusChipVariant { filled, outlined }

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;
  final StatusChipVariant variant;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.isSelected = true,
    this.onTap,
    this.variant = StatusChipVariant.filled,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = isSelected;
    final bgColor = isActive
        ? color.withValues(alpha: variant == StatusChipVariant.filled ? 0.1 : 0.15)
        : SasColors.glassBg;
    final borderColor = isActive
        ? color.withValues(alpha: variant == StatusChipVariant.filled ? 0.3 : 0.5)
        : SasColors.glassBorder;
    final textColor = isActive ? color : SasColors.textMuted;

    final child = AnimatedContainer(
      duration: SasDurations.fast,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: SasRadius.xlAll,
        border: Border.all(
          color: borderColor,
          width: isActive && variant == StatusChipVariant.outlined ? 2 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }
}
