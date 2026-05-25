
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/features/settings/providers/preferences_provider.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_app_bar.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      appBar: const GlassAppBar(title: 'Goals & Targets'),
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attendance Target',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    const Text(
                      'Set the minimum attendance percentage you want to maintain across all subjects.',
                      style: TextStyle(
                          color: SasColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '${prefs.attendanceTarget.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: prefs.attendanceTarget >= 75
                              ? SasColors.success
                              : SasColors.warning,
                          fontWeight: FontWeight.w800,
                          fontSize: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: SasColors.accentEmerald,
                        inactiveTrackColor:
                            SasColors.glassBg,
                        thumbColor: SasColors.accentEmerald,
                        overlayColor:
                            SasColors.accentEmerald.withValues(alpha: 0.1),
                        valueIndicatorColor: SasColors.bgSurface,
                        valueIndicatorTextStyle: const TextStyle(
                            color: SasColors.textPrimary),
                      ),
                      child: Slider(
                        value: prefs.attendanceTarget,
                        min: 50,
                        max: 100,
                        divisions: 10,
                        label: '${prefs.attendanceTarget.toStringAsFixed(0)}%',
                        onChanged: (v) => notifier.setAttendanceTarget(v),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('50%',
                            style: TextStyle(
                                color: SasColors.textMuted, fontSize: 12)),
                        Text('75% (recommended)',
                            style: TextStyle(
                                color: SasColors.textMuted, fontSize: 12)),
                        Text('100%',
                            style: TextStyle(
                                color: SasColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                borderColor: SasColors.info.withValues(alpha: 0.3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: SasColors.info, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Most universities require 75% attendance. Setting a higher target gives you a safety buffer.',
                        style: TextStyle(
                            color: SasColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
