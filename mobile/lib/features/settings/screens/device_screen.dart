// Device & Security screen — bound device info and reset request.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/data/api/auth_api.dart';
import 'package:smart_attendance_app/data/local/device_service.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_app_bar.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class DeviceScreen extends ConsumerStatefulWidget {
  const DeviceScreen({super.key});

  @override
  ConsumerState<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends ConsumerState<DeviceScreen> {
  String? _deviceId;
  bool _isLoading = false;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceId() async {
    final id = await ref.read(deviceServiceProvider).getDeviceUUID();
    if (mounted) setState(() => _deviceId = id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Device & Security'),
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Bound device info
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: SasColors.accentEmerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.smartphone_rounded,
                              color: SasColors.accentEmerald, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bound Device',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            Text('This device is registered to your account',
                                style: TextStyle(
                                    color: SasColors.textMuted,
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: SasColors.glassBorder, height: 1),
                    const SizedBox(height: 16),
                    _InfoRow(
                      label: 'Device ID',
                      value: _deviceId != null
                          ? '${_deviceId!.substring(0, 8)}…${_deviceId!.substring(_deviceId!.length - 8)}'
                          : 'Loading…',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Platform',
                      value: Theme.of(context).platform ==
                              TargetPlatform.android
                          ? 'Android'
                          : 'iOS',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Status',
                      value: 'Active',
                      valueColor: SasColors.success,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Device reset request
              GlassCard(
                borderColor: SasColors.warning.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: SasColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.device_unknown_rounded,
                              color: SasColors.warning, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Request Device Reset',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              Text(
                                  'Changed device? Request admin to unbind this one.',
                                  style: TextStyle(
                                      color: SasColors.textMuted,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      maxLength: 250,
                      style: const TextStyle(
                          color: SasColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            'Reason for reset (e.g., lost phone, new device)…',
                        hintStyle: const TextStyle(
                            color: SasColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: SasColors.glassBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: SasColors.glassBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: SasColors.glassBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: SasColors.glassBorderHover),
                        ),
                        counterStyle: const TextStyle(
                            color: SasColors.textMuted, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassButton(
                      label: 'Send Reset Request',
                      isExpanded: true,
                      isLoading: _isLoading,
                      icon: Icons.send_rounded,
                      onPressed: _isLoading ? null : _sendResetRequest,
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
                        color: SasColors.info, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Device reset requests are reviewed by administrators. You will be notified once approved. Expected resolution: 1–2 business days.',
                        style: TextStyle(
                            color: SasColors.textSecondary, fontSize: 12),
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

  Future<void> _sendResetRequest() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authApiProvider).requestDeviceReset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device reset request sent successfully.'),
            backgroundColor: SasColors.success,
          ),
        );
        _noteController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: SasColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: SasColors.textMuted, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor ?? SasColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
