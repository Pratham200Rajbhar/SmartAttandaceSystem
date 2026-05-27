
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_attendance_app/core/constants.dart';
import 'package:smart_attendance_app/domain/models/offline_payload.dart';
import 'package:smart_attendance_app/domain/models/user.dart';
import 'package:smart_attendance_app/domain/models/system_configuration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  Box<OfflineAttendancePayload>? _offlineBox;
  Box<String>? _profileBox;
  Box<String>? _configBox;

  Future<void> initialize() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(OfflineAttendancePayloadAdapter());
    }

    _offlineBox = await Hive.openBox<OfflineAttendancePayload>(
      kHiveBoxOfflineQueue,
    );
    _profileBox = await Hive.openBox<String>(kHiveBoxProfile);
    _configBox = await Hive.openBox<String>(kHiveBoxConfig);
  }

  Future<void> addToQueue(OfflineAttendancePayload payload) async {
    await _offlineBox?.add(payload);
  }

  List<OfflineAttendancePayload> getQueue() {
    return _offlineBox?.values.toList() ?? [];
  }

  Future<void> removeFromQueue(int key) async {
    await _offlineBox?.delete(key);
  }

  int get pendingCount => _offlineBox?.length ?? 0;

  Future<void> cacheProfile(UserProfile profile) async {
    await _profileBox?.put('user_profile', jsonEncode(profile.toJson()));
  }

  UserProfile? getCachedProfile() {
    final raw = _profileBox?.get('user_profile');
    if (raw == null) return null;
    return UserProfile.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> cacheSystemConfig(SystemConfiguration config) async {
    await _configBox?.put('system_config', jsonEncode(config.toJson()));
  }

  SystemConfiguration getSystemConfig() {
    final raw = _configBox?.get('system_config');
    if (raw == null) {
      return SystemConfiguration(
        isFaceRecognitionEnabled: true,
        isGpsVerificationEnabled: true,
        isAiBackgroundValidationEnabled: true,
      );
    }
    return SystemConfiguration.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> clearAll() async {
    await _offlineBox?.clear();
    await _profileBox?.clear();
    await _configBox?.clear();
  }
}
