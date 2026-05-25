// Secure storage wrapper for sensitive data (JWT, device UUID).
// Uses platform-native secure storage (Keychain on iOS, EncryptedSharedPreferences on Android).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_attendance_app/core/constants.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Stores the JWT access token.
  Future<void> saveToken(String token) async {
    await _storage.write(key: kSecureKeyJwt, value: token);
  }

  /// Retrieves the stored JWT token, or null if not present.
  Future<String?> getToken() async {
    return _storage.read(key: kSecureKeyJwt);
  }

  /// Stores the user's assigned role for offline route guards.
  Future<void> saveUserRole(String role) async {
    await _storage.write(key: kSecureKeyUserRole, value: role);
  }

  /// Retrieves the cached role.
  Future<String?> getRole() async {
    return _storage.read(key: kSecureKeyUserRole);
  }

  /// Stores the hardware-derived device UUID for device binding.
  Future<void> saveDeviceUUID(String uuid) async {
    await _storage.write(key: kSecureKeyDeviceUuid, value: uuid);
  }

  /// Retrieves the stored device UUID.
  Future<String?> getDeviceUUID() async {
    return _storage.read(key: kSecureKeyDeviceUuid);
  }

  /// Wipes all stored credentials on logout or auth failure.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
