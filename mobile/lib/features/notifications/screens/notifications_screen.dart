
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/core/attendance_constants.dart';
import 'package:smart_attendance_app/core/extensions.dart';
import 'package:smart_attendance_app/data/local/notification_service.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_app_bar.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final isLoading = ref.watch(notificationsLoadingProvider);
    final pushNotifications = notifications.where((n) => n.source == kAttendanceTypePush).toList();
    final localNotifications = notifications.where((n) => n.source == kAttendanceTypeLocal).toList();

    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Notifications',
        actions: [
          if (notifications.isNotEmpty) ...[
            Semantics(
              label: 'Mark all notifications as read',
              child: IconButton(
                icon: const Icon(Icons.done_all_rounded,
                    color: SasColors.textMuted),
                onPressed: () {
                  ref.read(notificationsProvider.notifier).markAllRead();
                },
                tooltip: 'Mark All Read',
              ),
            ),
            Semantics(
              label: 'Clear all notifications',
              child: IconButton(
                icon: const Icon(Icons.clear_all_rounded,
                    color: SasColors.textMuted),
                onPressed: () {
                  ref.read(notificationsProvider.notifier).clear();
                },
                tooltip: 'Clear All',
              ),
            ),
            const SizedBox(width: 4),
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
              child: Text('$unreadCount',
                  style: const TextStyle(
                      color: SasColors.accentEmerald,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: SasColors.accentEmerald,
            backgroundColor: SasColors.bgSecondary,
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [

              if (isLoading)
                _ShimmerNotifications()
              else if (notifications.isEmpty)
                GlassCard(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Icon(Icons.notifications_none_rounded,
                          size: 48,
                          color: SasColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text('No notifications yet',
                          style: TextStyle(
                              color: SasColors.textMuted,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text(
                          'Offline sync results and push alerts appear here.',
                          style: TextStyle(
                              color: SasColors.textMuted, fontSize: 13)),
                      const SizedBox(height: 16),
                    ],
                  ),
                )
              else ...[
                
                if (pushNotifications.isNotEmpty) ...[
                  const _SectionHeader(
                    icon: Icons.campaign_rounded,
                    title: 'Alerts',
                    color: SasColors.warning,
                  ),
                  const SizedBox(height: 8),
                  ...pushNotifications.map((n) => _NotificationTile(
                        notification: n,
                        isPush: true,
                      )),
                  const SizedBox(height: 16),
                ],
                
                if (localNotifications.isNotEmpty) ...[
                  const _SectionHeader(
                    icon: Icons.cloud_sync_rounded,
                    title: 'Sync Events',
                    color: SasColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  ...localNotifications.map((n) => _NotificationTile(
                        notification: n,
                        isPush: false,
                      )),
                ],
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _ShimmerNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: SasColors.glassBg,
      highlightColor: SasColors.glassBgHover,
      child: Column(
        children: List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: SasColors.glassBg,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final LocalNotification notification;
  final bool isPush;
  const _NotificationTile({required this.notification, required this.isPush});

  @override
  Widget build(BuildContext context) {
    final iconData = _getSeverityIcon(notification.severity);
    final borderColor = isPush
        ? iconData.color.withValues(alpha: 0.3)
        : notification.isRead ? null : SasColors.accentEmerald.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderColor: borderColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            if (!notification.isRead)
              Container(
                width: 4,
                height: 40,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: SasColors.accentEmerald,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconData.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData.icon, size: 20, color: iconData.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                                fontSize: 14)),
                      ),
                      if (isPush)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SasColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('PUSH',
                              style: TextStyle(
                                  color: SasColors.warning,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.body,
                      style: const TextStyle(
                          color: SasColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(notification.timestamp.formattedDateTime,
                      style: const TextStyle(
                          color: SasColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({IconData icon, Color color}) _getSeverityIcon(String severity) {
    switch (severity) {
      case kSeveritySuccess:
        return (
          icon: Icons.check_circle_outline_rounded,
          color: SasColors.success
        );
      case kSeverityWarning:
        return (icon: Icons.warning_amber_rounded, color: SasColors.warning);
      case kSeverityDanger:
        return (icon: Icons.error_outline_rounded, color: SasColors.danger);
      case kSeverityInfo:
      default:
        return (icon: Icons.info_outline_rounded, color: SasColors.info);
    }
  }
}
