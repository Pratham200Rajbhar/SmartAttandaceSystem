import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/features/auth/providers/auth_provider.dart';
import 'package:smart_attendance_app/data/local/pending_count_provider.dart';
import 'package:smart_attendance_app/data/local/notification_service.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';
import 'package:smart_attendance_app/shared/widgets/menu_grid_item.dart';
import 'package:smart_attendance_app/shared/widgets/section_header.dart';
import 'package:smart_attendance_app/shared/widgets/status_chip.dart';

/// "More" tab — profile card, quick actions grid, settings menu, sign out.
/// Restructured from the old ProfileScreen that tried to be both a profile
/// view and a settings/navigation hub.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final pendingCount = ref.watch(pendingCountProvider);
    final profile = user?.studentProfile;
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return AnimatedBackground(
      child: SafeArea(
        child: ListView(
          padding: SasSpacing.screenPadding,
          children: [
            // --- Profile Card ---
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
                        color:
                            SasColors.accentEmerald.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: SasColors.accentEmerald,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: SasSpacing.md),
                  Text(
                    (profile?.firstName != null &&
                            profile?.lastName != null)
                        ? '${profile!.firstName} ${profile.lastName}'
                        : user?.email ?? 'Student',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  if (profile != null) ...[
                    const SizedBox(height: SasSpacing.xs),
                    Text(
                      profile.enrollmentNumber,
                      style: const TextStyle(
                        color: SasColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: SasSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StatusChip(
                        label: user?.role ?? 'STUDENT',
                        color: SasColors.accentEmerald,
                      ),
                      const SizedBox(width: SasSpacing.sm),
                      StatusChip(
                        label: profile?.faceRegistered == true
                            ? 'Face ID ✓'
                            : 'Face ID Pending',
                        color: profile?.faceRegistered == true
                            ? SasColors.success
                            : SasColors.warning,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: SasSpacing.xl),

            // --- Quick Actions Grid ---
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: SasSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: MenuGridItem(
                    icon: Icons.qr_code_2_rounded,
                    label: 'Smart Pass',
                    subtitle: 'Campus QR',
                    iconColor: SasColors.accentEmerald,
                    onTap: () => context.push('/smart-pass'),
                  ),
                ),
                const SizedBox(width: SasSpacing.sm),
                Expanded(
                  child: MenuGridItem(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    subtitle: 'Alerts & sync',
                    iconColor: SasColors.warning,
                    badgeCount: unreadCount,
                    onTap: () => context.push('/notifications'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SasSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: MenuGridItem(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Request Leave',
                    subtitle: 'Submit new',
                    iconColor: SasColors.info,
                    onTap: () => context.push('/leave/request'),
                  ),
                ),
                const SizedBox(width: SasSpacing.sm),
                Expanded(
                  child: MenuGridItem(
                    icon: Icons.history_rounded,
                    label: 'Leave History',
                    subtitle: 'All requests',
                    iconColor: SasColors.accentTeal,
                    onTap: () => context.push('/leave/history'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: SasSpacing.xl),

            // --- Settings ---
            const SectionHeader(title: 'Settings'),
            const SizedBox(height: SasSpacing.sm),
            _MenuItem(
              icon: Icons.track_changes_rounded,
              title: 'Goals & Targets',
              subtitle: 'Set attendance target percentage',
              onTap: () => context.push('/settings/goals'),
            ),
            const SizedBox(height: 6),
            _MenuItem(
              icon: Icons.notifications_rounded,
              title: 'Notification Preferences',
              subtitle: 'Manage alerts and reminders',
              onTap: () => context.push('/settings/notifications'),
            ),
            const SizedBox(height: 6),
            _MenuItem(
              icon: Icons.cloud_sync_rounded,
              title: 'Offline Sync Status',
              subtitle: pendingCount > 0
                  ? '$pendingCount pending submission${pendingCount == 1 ? '' : 's'}'
                  : 'All synced',
              onTap: () => context.push('/settings/sync'),
              trailing: pendingCount > 0
                  ? StatusChip(
                      label: '$pendingCount',
                      color: SasColors.info,
                    )
                  : Icon(
                      Icons.check_circle_rounded,
                      color: SasColors.success.withValues(alpha: 0.7),
                      size: 18,
                    ),
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

            const SizedBox(height: SasSpacing.xxl),

            // --- Sign Out ---
            GlassButton(
              label: 'Sign Out',
              variant: GlassButtonVariant.danger,
              isExpanded: true,
              icon: Icons.logout_rounded,
              onPressed: () => _confirmLogout(context, ref),
            ),

            const SizedBox(height: SasSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SasColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: SasRadius.xlAll,
          side: const BorderSide(color: SasColors.glassBorder),
        ),
        title: const Text(
          'Sign Out?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'You will need to sign in again to mark attendance.',
          style: TextStyle(color: SasColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: SasColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: SasColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private: Settings menu item (specific to this screen's layout)
// ---------------------------------------------------------------------------

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
              borderRadius: SasRadius.mdAll,
            ),
            child: Icon(icon, size: 18, color: SasColors.textSecondary),
          ),
          const SizedBox(width: SasSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: SasColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              (onTap != null
                  ? const Icon(
                      Icons.chevron_right_rounded,
                      color: SasColors.textMuted,
                      size: 18,
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    );
  }
}
