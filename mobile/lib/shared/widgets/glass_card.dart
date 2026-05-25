
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: SasColors.glassBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? SasColors.glassBorder,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x8C000000),
                  blurRadius: 48,
                  offset: Offset(0, 16),
                ),
              ],
              
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.04),
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.01),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
