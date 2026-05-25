
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/features/settings/providers/preferences_provider.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_app_bar.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class NotificationPrefsScreen extends ConsumerWidget {
  const NotificationPrefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      appBar: const GlassAppBar(title: 'Notification Preferences'),
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Choose which notifications you want to receive.',
                style:
                    TextStyle(color: SasColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _ToggleTile(
                icon: Icons.schedule_rounded,
                title: 'Class Starting Soon',
                subtitle: 'Alert 15 minutes before a class begins',
                value: prefs.notifyClassStart,
                onChanged: notifier.setNotifyClassStart,
              ),
              const SizedBox(height: 8),
              _ToggleTile(
                icon: Icons.fingerprint_rounded,
                title: 'Attendance Window Open',
                subtitle: 'Alert when a teacher opens an attendance session',
                value: prefs.notifyWindowOpen,
                onChanged: notifier.setNotifyWindowOpen,
              ),
              const SizedBox(height: 8),
              _ToggleTile(
                icon: Icons.cloud_done_rounded,
                title: 'Sync Completed',
                subtitle: 'Alert when offline submissions are synced',
                value: prefs.notifySyncDone,
                onChanged: notifier.setNotifySyncDone,
              ),
              const SizedBox(height: 8),
              _ToggleTile(
                icon: Icons.warning_amber_rounded,
                title: 'Low Attendance Warning',
                subtitle: 'Alert when attendance drops below your target',
                value: prefs.notifyLowAttendance,
                onChanged: notifier.setNotifyLowAttendance,
              ),
              if (prefs.notifyLowAttendance) ...[
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Warning Threshold',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        'Warn me when attendance falls below ${prefs.lowAttendanceThreshold.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: SasColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: SasColors.warning,
                          inactiveTrackColor: SasColors.glassBg,
                          thumbColor: SasColors.warning,
                          overlayColor:
                              SasColors.warning.withValues(alpha: 0.1),
                        ),
                        child: Slider(
                          value: prefs.lowAttendanceThreshold,
                          min: 50,
                          max: 90,
                          divisions: 8,
                          label:
                              '${prefs.lowAttendanceThreshold.toStringAsFixed(0)}%',
                          onChanged: notifier.setLowAttendanceThreshold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: SasColors.glassBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: SasColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        color: SasColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: SasColors.accentEmerald,
            inactiveThumbColor: SasColors.textMuted,
            inactiveTrackColor: SasColors.glassBg,
          ),
        ],
      ),
    );
  }
}
