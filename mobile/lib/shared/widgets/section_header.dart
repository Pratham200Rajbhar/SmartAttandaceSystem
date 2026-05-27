import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';

/// Section header for grouping menu items and content areas.
/// Replaces _SectionHeader in profile, notifications, and other screens.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? color;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? SasColors.textMuted;

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: displayColor),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            icon != null ? title : title.toUpperCase(),
            style: TextStyle(
              color: displayColor,
              fontSize: icon != null ? 13 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: icon != null ? 0 : 1.2,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
