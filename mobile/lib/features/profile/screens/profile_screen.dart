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

  String _getInitials(dynamic profile, dynamic user) {
    if (profile?.firstName != null && profile?.lastName != null) {
      final String first = profile.firstName;
      final String last = profile.lastName;
      if (first.isNotEmpty && last.isNotEmpty) {
        return '${first[0]}${last[0]}'.toUpperCase();
      }
    }
    final String? email = user?.email;
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'S';
  }

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
              child: Row(
                children: [
                  // Glowing Avatar Ring
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          SasColors.accentEmerald,
                          SasColors.accentTeal,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: SasColors.accentEmerald.withValues(alpha: 0.25),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: SasColors.accentEmerald.withValues(alpha: 0.45),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(profile, user),
                        style: const TextStyle(
                          color: SasColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: SasSpacing.lg),
                  // Profile Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (profile?.firstName != null && profile?.lastName != null)
                              ? '${profile!.firstName} ${profile.lastName}'
                              : user?.email ?? 'Student',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: SasColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (profile != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Roll No: ${profile.enrollmentNumber}',
                            style: const TextStyle(
                              color: SasColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: SasColors.accentEmerald.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: SasColors.accentEmerald.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                user?.role.toUpperCase() ?? 'STUDENT',
                                style: const TextStyle(
                                  color: SasColors.accentEmerald,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (profile?.faceRegistered == true
                                        ? SasColors.success
                                        : SasColors.warning)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: (profile?.faceRegistered == true
                                          ? SasColors.success
                                          : SasColors.warning)
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    profile?.faceRegistered == true
                                        ? Icons.face_unlock_rounded
                                        : Icons.face_rounded,
                                    size: 10,
                                    color: profile?.faceRegistered == true
                                        ? SasColors.success
                                        : SasColors.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile?.faceRegistered == true ? 'Face ID Verified' : 'Face ID Pending',
                                    style: TextStyle(
                                      color: profile?.faceRegistered == true
                                          ? SasColors.success
                                          : SasColors.warning,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
            _SettingsGroup(
              items: [
                _MenuItem(
                  icon: Icons.track_changes_rounded,
                  iconColor: SasColors.success,
                  title: 'Goals & Targets',
                  subtitle: 'Set attendance target percentage',
                  onTap: () => context.push('/settings/goals'),
                ),
                _MenuItem(
                  icon: Icons.notifications_rounded,
                  iconColor: SasColors.warning,
                  title: 'Notification Preferences',
                  subtitle: 'Manage alerts and reminders',
                  onTap: () => context.push('/settings/notifications'),
                ),
                _MenuItem(
                  icon: Icons.cloud_sync_rounded,
                  iconColor: SasColors.info,
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
                _MenuItem(
                  icon: Icons.help_outline_rounded,
                  iconColor: Colors.purpleAccent,
                  title: 'Help & FAQ',
                  subtitle: 'Common questions and answers',
                  onTap: () => context.push('/settings/help'),
                ),
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  iconColor: SasColors.accentTeal,
                  title: 'About',
                  subtitle: 'Smart Attendance System v1.0.0',
                  onTap: null,
                ),
              ],
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
// Private: Grouped Settings wrapper (renders as a single unified card)
// ---------------------------------------------------------------------------

class _SettingsGroup extends StatelessWidget {
  final List<Widget> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: SasColors.glassBorder,
                indent: 52,
              ),
          ],
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
  final Color iconColor;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor = SasColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: SasRadius.mdAll,
                ),
                child: Icon(icon, size: 18, color: iconColor),
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
                        color: SasColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: SasColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SasSpacing.sm),
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
        ),
      ),
    );
  }
}
