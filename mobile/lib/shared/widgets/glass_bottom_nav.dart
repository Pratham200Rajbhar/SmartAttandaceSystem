
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';

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
      ('Attendance', Icons.fact_check_rounded),
      ('Analytics', Icons.bar_chart_rounded),
      ('Profile', Icons.person_rounded),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: SasColors.bgSurface.withValues(alpha: 0.7),
            border: const Border(top: BorderSide(color: SasColors.glassBorder)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final sel = i == currentIndex;
                  return Expanded(
                    child: Semantics(
                      label: '${items[i].$1} tab${sel ? ', selected' : ''}',
                      child: InkWell(
                        onTap: () => onTap(i),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: sel
                              ? BoxDecoration(
                                  color: SasColors.accentEmerald
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: SasColors.accentEmerald
                                          .withValues(alpha: 0.2)),
                                )
                              : null,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(items[i].$2,
                                  size: 22,
                                  color: sel
                                      ? SasColors.accentEmerald
                                      : SasColors.textMuted),
                              const SizedBox(height: 4),
                              Text(items[i].$1,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: sel
                                        ? SasColors.accentEmerald
                                        : SasColors.textMuted,
                                  )),
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
