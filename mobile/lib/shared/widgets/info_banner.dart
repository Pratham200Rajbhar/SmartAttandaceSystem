import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

/// Severity levels for info banners — drives icon and color selection.
enum BannerSeverity { info, success, warning, danger }

/// Reusable info/warning/error banner replacing inline banner widgets
/// across home, verification, and other screens.
class InfoBanner extends StatelessWidget {
  final String message;
  final BannerSeverity severity;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? customIcon;

  const InfoBanner({
    super.key,
    required this.message,
    this.severity = BannerSeverity.info,
    this.actionLabel,
    this.onAction,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig();

    return GlassCard(
      borderColor: config.color.withValues(alpha: 0.3),
      child: Column(
        children: [
          const SizedBox(height: SasSpacing.sm),
          Icon(
            customIcon ?? config.icon,
            size: 40,
            color: config.color,
          ),
          const SizedBox(height: SasSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SasColors.textSecondary,
              fontSize: 14,
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: SasSpacing.lg),
            GlassButton(
              label: actionLabel!,
              icon: Icons.refresh_rounded,
              onPressed: onAction,
            ),
          ],
          const SizedBox(height: SasSpacing.sm),
        ],
      ),
    );
  }

  _BannerConfig _resolveConfig() {
    return switch (severity) {
      BannerSeverity.info => _BannerConfig(
          color: SasColors.info,
          icon: Icons.info_outline_rounded,
        ),
      BannerSeverity.success => _BannerConfig(
          color: SasColors.success,
          icon: Icons.check_circle_outline_rounded,
        ),
      BannerSeverity.warning => _BannerConfig(
          color: SasColors.warning,
          icon: Icons.warning_amber_rounded,
        ),
      BannerSeverity.danger => _BannerConfig(
          color: SasColors.danger,
          icon: Icons.error_outline_rounded,
        ),
    };
  }
}

class _BannerConfig {
  final Color color;
  final IconData icon;
  const _BannerConfig({required this.color, required this.icon});
}

/// A compact inline banner — horizontal layout for context-sensitive messages.
/// Used for warnings within forms, quality checks, etc.
class InlineInfoBanner extends StatelessWidget {
  final String message;
  final BannerSeverity severity;

  const InlineInfoBanner({
    super.key,
    required this.message,
    this.severity = BannerSeverity.warning,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      BannerSeverity.info => SasColors.info,
      BannerSeverity.success => SasColors.success,
      BannerSeverity.warning => SasColors.warning,
      BannerSeverity.danger => SasColors.danger,
    };
    final icon = switch (severity) {
      BannerSeverity.info => Icons.info_outline_rounded,
      BannerSeverity.success => Icons.check_circle_outline_rounded,
      BannerSeverity.warning => Icons.warning_amber_rounded,
      BannerSeverity.danger => Icons.error_outline_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(SasSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: SasRadius.smAll,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: SasSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
