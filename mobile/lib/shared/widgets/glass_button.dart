
import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';

enum GlassButtonVariant { primary, secondary, danger, ghost }

class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final double? height;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = GlassButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();
    final disabled = onPressed == null || isLoading;

    Widget child = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(colors.foreground),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: colors.foreground),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
      ],
    );

    return AnimatedOpacity(
      opacity: disabled ? 0.45 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withValues(alpha: 0.05),
          child: Container(
            height: height ?? 48,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
              boxShadow: variant == GlassButtonVariant.ghost
                  ? null
                  : [
                      const BoxShadow(
                        color: Color(0x80000000),
                        blurRadius: 18,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  _ButtonColors _resolveColors() {
    switch (variant) {
      case GlassButtonVariant.primary:
        return _ButtonColors(
          background: const Color(0x1AFFFFFF), 
          foreground: Colors.white,
          border: const Color(0x33FFFFFF), 
        );
      case GlassButtonVariant.secondary:
        return _ButtonColors(
          background: SasColors.glassBg,
          foreground: SasColors.textPrimary,
          border: SasColors.glassBorder,
        );
      case GlassButtonVariant.danger:
        return _ButtonColors(
          background: SasColors.accentPink.withValues(alpha: 0.15),
          foreground: Colors.white,
          border: SasColors.accentPink.withValues(alpha: 0.4),
        );
      case GlassButtonVariant.ghost:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: SasColors.textSecondary,
          border: Colors.transparent,
        );
    }
  }
}

class _ButtonColors {
  final Color background;
  final Color foreground;
  final Color border;

  const _ButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });
}
