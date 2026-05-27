import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/data/api/dio_client.dart';
import 'package:smart_attendance_app/data/local/device_service.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_input.dart';
import 'package:smart_attendance_app/utils/logger.dart';

class DeviceChangeDialog extends ConsumerStatefulWidget {
  final String email;
  final String password;

  const DeviceChangeDialog({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  ConsumerState<DeviceChangeDialog> createState() => _DeviceChangeDialogState();
}

class _DeviceChangeDialogState extends ConsumerState<DeviceChangeDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final deviceService = ref.read(deviceServiceProvider);
      final newDeviceUuid = await deviceService.getDeviceUUID();

      await dio.post('/auth/request-device-change', data: {
        'email': widget.email,
        'password': widget.password,
        'new_device_uuid': newDeviceUuid,
        'reason': _reasonController.text.trim(),
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      AppLogger.error('Failed to request device change: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit request. Please try again.'),
          backgroundColor: SasColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SasColors.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.smartphone, color: SasColors.accentEmerald),
          SizedBox(width: 8),
          Expanded(child: Text('Device Binding Error', style: TextStyle(color: SasColors.textPrimary))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Your account is bound to another device. If you got a new phone, you can request your teacher to authorize this new device.',
            style: TextStyle(color: SasColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 16),
          GlassInput(
            controller: _reasonController,
            label: 'Reason (Optional)',
            hint: 'e.g., Bought a new phone',
            prefixIcon: Icons.edit_note,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel', style: TextStyle(color: SasColors.textMuted)),
        ),
        GlassButton(
          label: 'Request',
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _submitRequest,
          isExpanded: false,
        ),
      ],
    );
  }
}
