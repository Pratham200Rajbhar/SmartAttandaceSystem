
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/features/auth/providers/auth_provider.dart';
import 'package:smart_attendance_app/features/home/screens/home_screen.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final pendingCount = ref.watch(pendingCountProvider);
    final profile = user?.studentProfile;

    return AnimatedBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            
            GlassCard(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [
                        SasColors.accentEmerald.withValues(alpha: 0.2),
                        SasColors.accentTeal.withValues(alpha: 0.1),
                      ]),
                      border: Border.all(
                          color: SasColors.accentEmerald.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: SasColors.accentEmerald, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (profile?.firstName != null && profile?.lastName != null)
                        ? '${profile!.firstName} ${profile.lastName}'
                        : user?.email ?? 'Student',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                  if (profile != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      profile.enrollmentNumber,
                      style: const TextStyle(
                          color: SasColors.textMuted, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: SasColors.accentEmerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: SasColors.accentEmerald
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Text(user?.role ?? 'STUDENT',
                            style: const TextStyle(
                                color: SasColors.accentEmerald,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (profile?.faceRegistered == true
                                  ? SasColors.success
                                  : SasColors.warning)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: (profile?.faceRegistered == true
                                      ? SasColors.success
                                      : SasColors.warning)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          profile?.faceRegistered == true
                              ? 'Face ID ✓'
                              : 'Face ID Pending',
                          style: TextStyle(
                              color: profile?.faceRegistered == true
                                  ? SasColors.success
                                  : SasColors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _SectionHeader(title: 'Attendance'),
            const SizedBox(height: 8),
            _MenuItem(
              icon: Icons.track_changes_rounded,
              title: 'Goals & Targets',
              subtitle: 'Set your attendance target percentage',
              onTap: () => context.push('/settings/goals'),
            ),
            const SizedBox(height: 6),
            _MenuItem(
              icon: Icons.history_rounded,
              title: 'Attendance History',
              subtitle: 'View all records and calendar',
              onTap: () => context.go('/attendance'),
            ),

            const SizedBox(height: 16),

            _SectionHeader(title: 'Notifications'),
            const SizedBox(height: 8),
            _MenuItem(
              icon: Icons.notifications_rounded,
              title: 'Notification Preferences',
              subtitle: 'Manage alerts and reminders',
              onTap: () => context.push('/settings/notifications'),
            ),
            const SizedBox(height: 6),
            _MenuItem(
              icon: Icons.campaign_rounded,
              title: 'Notification Log',
              subtitle: 'View all alerts and sync events',
              onTap: () => context.push('/notifications'),
            ),

            const SizedBox(height: 16),

            _SectionHeader(title: 'Security'),
            const SizedBox(height: 8),
            _MenuItem(
              icon: Icons.devices_rounded,
              title: 'Device & Security',
              subtitle: 'Bound device info and reset request',
              onTap: () => context.push('/settings/device'),
            ),

            const SizedBox(height: 16),

            _SectionHeader(title: 'App'),
            const SizedBox(height: 8),
            _MenuItem(
              icon: Icons.cloud_sync_rounded,
              title: 'Offline Sync Status',
              subtitle: pendingCount > 0
                  ? '$pendingCount pending submission${pendingCount == 1 ? '' : 's'}'
                  : 'All synced',
              onTap: () => context.push('/settings/sync'),
              trailing: pendingCount > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: SasColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: SasColors.info.withValues(alpha: 0.3)),
                      ),
                      child: Text('$pendingCount',
                          style: const TextStyle(
                              color: SasColors.info,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    )
                  : Icon(Icons.check_circle_rounded,
                      color: SasColors.success.withValues(alpha: 0.7),
                      size: 18),
            ),
            const SizedBox(height: 6),
            _MenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Help & FAQ',
              subtitle: 'Common questions and answers',
              onTap: () => context.push('/settings/help'),
            ),
            const SizedBox(height: 6),
            _MenuItem(
              icon: Icons.info_outline_rounded,
              title: 'About',
              subtitle: 'Smart Attendance System v1.0.0',
              onTap: null,
            ),

            const SizedBox(height: 24),

            GlassButton(
              label: 'Sign Out',
              variant: GlassButtonVariant.danger,
              isExpanded: true,
              icon: Icons.logout_rounded,
              onPressed: () => _confirmLogout(context, ref),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: SasColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
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
          trailing ??
              (onTap != null
                  ? const Icon(Icons.chevron_right_rounded,
                      color: SasColors.textMuted, size: 18)
                  : const SizedBox.shrink()),
        ],
      ),
    );
  }
}
