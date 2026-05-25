// Settings screen — profile, app info, device reset, logout.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/data/api/auth_api.dart';
import 'package:smart_attendance_app/features/auth/providers/auth_provider.dart';
import 'package:smart_attendance_app/features/home/screens/home_screen.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final pendingCount = ref.watch(pendingCountProvider);

    return AnimatedBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Settings',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 20),

            // Profile card
            GlassCard(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [
                        SasColors.accentEmerald.withValues(alpha: 0.2),
                        SasColors.accentTeal.withValues(alpha: 0.1),
                      ]),
                      border: Border.all(
                          color:
                              SasColors.accentEmerald.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: SasColors.accentEmerald, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (user?.studentProfile?.firstName != null && user?.studentProfile?.lastName != null)
                        ? '${user!.studentProfile!.firstName} ${user.studentProfile!.lastName}'
                        : user?.email ?? 'Student',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                  if (user?.studentProfile != null) ...[
                    const SizedBox(height: 4),
                    Text(
                        'Enrollment: ${user!.studentProfile!.enrollmentNumber}',
                        style: const TextStyle(
                            color: SasColors.textMuted, fontSize: 13)),
                  ],
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: SasColors.accentEmerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(user?.role ?? 'STUDENT',
                        style: const TextStyle(
                            color: SasColors.accentEmerald,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Offline sync status
            _menuItem(
              Icons.cloud_sync_rounded,
              'Offline Queue',
              pendingCount > 0
                  ? '$pendingCount pending submission${pendingCount == 1 ? '' : 's'}'
                  : 'All synced',
              null,
              trailing: pendingCount > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: SasColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: SasColors.info.withValues(alpha: 0.3)),
                      ),
                      child: Text('$pendingCount',
                          style: const TextStyle(
                              color: SasColors.info,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    )
                  : Icon(Icons.check_circle_rounded,
                      color: SasColors.success.withValues(alpha: 0.7),
                      size: 20),
            ),

            const SizedBox(height: 8),

            // Device reset
            _menuItem(Icons.devices_rounded, 'Request Device Reset',
                'Contact admin to unbind your device', () {
              _showDeviceResetDialog(context, ref);
            }),

            const SizedBox(height: 8),

            _menuItem(Icons.info_outline_rounded, 'About',
                'Smart Attendance System v1.0.0', null),

            const SizedBox(height: 24),

            // Logout
            GlassButton(
              label: 'Sign Out',
              variant: GlassButtonVariant.danger,
              isExpanded: true,
              icon: Icons.logout_rounded,
              onPressed: () => _confirmLogout(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before logging out.
  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SasColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: SasColors.glassBorder),
        ),
        title: const Text('Sign Out?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'You will need to sign in again to mark attendance.',
          style: TextStyle(color: SasColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: SasColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
            },
            child: const Text('Sign Out',
                style: TextStyle(color: SasColors.danger)),
          ),
        ],
      ),
    );
  }

  /// Shows an dialog to request a device reset from the backend.
  void _showDeviceResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SasColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: SasColors.glassBorder),
        ),
        title: const Text('Device Reset',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Would you like to send a device reset request to the administrators? '
          'They will review your request and unbind your device if approved.',
          style: TextStyle(color: SasColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: SasColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                // Call the auth API instead of just showing info
                await ref.read(authApiProvider).requestDeviceReset();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Device reset request sent successfully.'),
                      backgroundColor: SasColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send request: $e'),
                      backgroundColor: SasColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Request Reset', style: TextStyle(color: SasColors.accentEmerald)),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
      IconData icon, String title, String subtitle, VoidCallback? onTap,
      {Widget? trailing}) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SasColors.glassBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: SasColors.textSecondary),
          ),
          const SizedBox(width: 14),
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
          )),
          trailing ??
              const Icon(Icons.chevron_right_rounded,
                  color: SasColors.textMuted, size: 20),
        ],
      ),
    );
  }
}
