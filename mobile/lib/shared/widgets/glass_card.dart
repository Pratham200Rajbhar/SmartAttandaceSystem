import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';

/// Glassmorphism card with optional backdrop blur.
///
/// [enableBlur] defaults to false for performance — BackdropFilter with
/// sigma=28 is extremely expensive when repeated across list items. Only
/// enable it on singular hero cards (app bar, bottom nav, login card).
/// Cards without blur still use the gradient + border for visual consistency.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final bool enableBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.onTap,
    this.borderColor,
    this.enableBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: SasColors.glassBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? SasColors.glassBorder,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 24,
          offset: const Offset(0, 8),
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
    );

    Widget content = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (enableBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}
