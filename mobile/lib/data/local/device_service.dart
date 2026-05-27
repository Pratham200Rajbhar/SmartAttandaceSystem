
library;
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/data/local/secure_storage.dart';

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService(ref.read(secureStorageProvider));
});

class DeviceService {
  final SecureStorageService _secureStorage;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  DeviceService(this._secureStorage);

  Future<String> getDeviceUUID() async {
    
    final storedUUID = await _secureStorage.getDeviceUUID();
    if (storedUUID != null) return storedUUID;

    String newUUID = 'unknown_device';
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        
        newUUID = 'android_${androidInfo.id}_${androidInfo.fingerprint}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        newUUID = 'ios_${iosInfo.identifierForVendor}';
      }
    } catch (_) {
      newUUID = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }

    await _secureStorage.saveDeviceUUID(newUUID);
    return newUUID;
  }
}
