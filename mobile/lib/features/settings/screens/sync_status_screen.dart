
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/data/local/hive_service.dart';
import 'package:smart_attendance_app/data/local/offline_sync_service.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_app_bar.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final hive = ref.watch(hiveServiceProvider);
    final queue = hive.getQueue();

    return Scaffold(
      appBar: const GlassAppBar(title: 'Offline Sync Status'),
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              
              GlassCard(
                borderColor: queue.isEmpty
                    ? SasColors.success.withValues(alpha: 0.3)
                    : SasColors.info.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (queue.isEmpty
                                ? SasColors.success
                                : SasColors.info)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        queue.isEmpty
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_sync_rounded,
                        color: queue.isEmpty
                            ? SasColors.success
                            : SasColors.info,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            queue.isEmpty
                                ? 'All Synced'
                                : '${queue.length} Pending',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          Text(
                            queue.isEmpty
                                ? 'No pending submissions'
                                : 'Waiting for network connection',
                            style: const TextStyle(
                                color: SasColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (queue.isNotEmpty)
                      GlassButton(
                        label: 'Sync Now',
                        isLoading: _isSyncing,
                        icon: Icons.refresh_rounded,
                        onPressed: _isSyncing ? null : _triggerSync,
                      ),
                  ],
                ),
              ),

              if (queue.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'PENDING SUBMISSIONS',
                  style: TextStyle(
                    color: SasColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                ...queue.map((payload) {
                  final age = DateTime.now().difference(payload.capturedAt);
                  final isExpiringSoon = age.inMinutes > 90;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      borderColor: isExpiringSoon
                          ? SasColors.warning.withValues(alpha: 0.3)
                          : null,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: SasColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.pending_rounded,
                                color: SasColors.info, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  payload.className ?? 'Unknown Class',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                                Text(
                                  'Captured ${DateFormat.jm().format(payload.capturedAt)} · ${_formatAge(age)}',
                                  style: const TextStyle(
                                      color: SasColors.textMuted,
                                      fontSize: 11),
                                ),
                                Text(
                                  'GPS: ${payload.latitude.toStringAsFixed(4)}, ${payload.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                      color: SasColors.textMuted,
                                      fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          if (isExpiringSoon)
                            const Icon(Icons.warning_amber_rounded,
                                color: SasColors.warning, size: 16),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                GlassCard(
                  borderColor: SasColors.warning.withValues(alpha: 0.3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: SasColors.warning, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Pending submissions expire after 2 hours. Connect to the internet to sync them.',
                          style: TextStyle(
                              color: SasColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.cloud_done_rounded,
                          size: 56,
                          color: SasColors.success.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text('Nothing pending',
                          style: TextStyle(
                              color: SasColors.textMuted,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('All your submissions are synced.',
                          style: TextStyle(
                              color: SasColors.textMuted, fontSize: 13)),
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

  String _formatAge(Duration age) {
    if (age.inMinutes < 1) return 'just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    return '${age.inHours}h ${age.inMinutes % 60}m ago';
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    try {
      await ref.read(offlineSyncServiceProvider).syncQueue();
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }
}
