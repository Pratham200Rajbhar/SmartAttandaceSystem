import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';

/// Chart legend indicator — replaces duplicate _LegendDot in analytics and history.
class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isCircle;

  const LegendDot({
    super.key,
    required this.color,
    required this.label,
    this.isCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: SasSpacing.xs),
        Text(
          label,
          style: const TextStyle(color: SasColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}
