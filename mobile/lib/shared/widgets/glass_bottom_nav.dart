import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_attendance_app/app/theme.dart';

/// Glassmorphic bottom navigation bar with haptic feedback and subtle animations.
class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Home', Icons.home_rounded),
      ('History', Icons.fact_check_rounded),
      ('Analytics', Icons.bar_chart_rounded),
      ('More', Icons.grid_view_rounded),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: SasColors.bgSurface.withValues(alpha: 0.7),
            border: const Border(
              top: BorderSide(color: SasColors.glassBorder),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SasSpacing.sm,
                vertical: SasSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final selected = i == currentIndex;
                  return Expanded(
                    child: Semantics(
                      label: '${items[i].$1} tab${selected ? ', selected' : ''}',
                      child: InkWell(
                        onTap: () {
                          if (i != currentIndex) {
                            HapticFeedback.selectionClick();
                          }
                          onTap(i);
                        },
                        borderRadius: SasRadius.mdAll,
                        child: AnimatedContainer(
                          duration: SasDurations.normal,
                          padding: const EdgeInsets.symmetric(
                            vertical: SasSpacing.sm,
                          ),
                          decoration: selected
                              ? BoxDecoration(
                                  color: SasColors.accentEmerald
                                      .withValues(alpha: 0.1),
                                  borderRadius: SasRadius.mdAll,
                                  border: Border.all(
                                    color: SasColors.accentEmerald
                                        .withValues(alpha: 0.2),
                                  ),
                                )
                              : null,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedScale(
                                scale: selected ? 1.15 : 1.0,
                                duration: SasDurations.normal,
                                child: Icon(
                                  items[i].$2,
                                  size: 22,
                                  color: selected
                                      ? SasColors.accentEmerald
                                      : SasColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: SasSpacing.xs),
                              Text(
                                items[i].$1,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? SasColors.accentEmerald
                                      : SasColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
