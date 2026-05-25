// Hardware device service using device_info_plus.
library;
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/data/local/secure_storage.dart';

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService(ref.read(secureStorageProvider));
});

class DeviceService {
  final SecureStorageService _secureStorage;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  DeviceService(this._secureStorage);

  /// Generates a hardware-locked UUID based on the device's physical identifiers.
  /// Stores it securely to ensure persistence across sessions.
  Future<String> getDeviceUUID() async {
    // Check if we already generated and stored it
    final storedUUID = await _secureStorage.getDeviceUUID();
    if (storedUUID != null) return storedUUID;

    // Generate new based on hardware
    String newUUID = 'unknown_device';
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Combining unique hardware markers
        newUUID = 'android_${androidInfo.id}_${androidInfo.fingerprint}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        newUUID = 'ios_${iosInfo.identifierForVendor}';
      }
    } catch (e, stackTrace) {
      debugPrint('DeviceService.getDeviceUUID error: $e\n$stackTrace');
      newUUID = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }

    await _secureStorage.saveDeviceUUID(newUUID);
    return newUUID;
  }
}
