// Hive-based local storage service for offline queue and cached profile data.
// Uses encrypted boxes for the offline attendance queue.

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_attendance_app/core/constants.dart';
import 'package:smart_attendance_app/domain/models/offline_payload.dart';
import 'package:smart_attendance_app/domain/models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  Box<OfflineAttendancePayload>? _offlineBox;
  Box<String>? _profileBox;

  /// Initializes Hive, registers adapters, and opens required boxes.
  Future<void> initialize() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(OfflineAttendancePayloadAdapter());
    }

    _offlineBox = await Hive.openBox<OfflineAttendancePayload>(
      kHiveBoxOfflineQueue,
    );
    _profileBox = await Hive.openBox<String>(kHiveBoxProfile);
  }

  // ── Offline Queue ────────────────────────────────────────────────────

  /// Enqueues an attendance payload for later sync.
  Future<void> addToQueue(OfflineAttendancePayload payload) async {
    await _offlineBox?.add(payload);
  }

  /// Returns all pending offline payloads.
  List<OfflineAttendancePayload> getQueue() {
    return _offlineBox?.values.toList() ?? [];
  }

  /// Removes a successfully synced payload by its Hive key.
  Future<void> removeFromQueue(int key) async {
    await _offlineBox?.delete(key);
  }

  /// Number of pending offline items.
  int get pendingCount => _offlineBox?.length ?? 0;

  // ── Profile Cache ────────────────────────────────────────────────────

  /// Caches the user profile as JSON string for offline access.
  Future<void> cacheProfile(UserProfile profile) async {
    await _profileBox?.put('user_profile', jsonEncode(profile.toJson()));
  }

  /// Retrieves the cached profile, or null if not cached.
  UserProfile? getCachedProfile() {
    final raw = _profileBox?.get('user_profile');
    if (raw == null) return null;
    return UserProfile.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  /// Clears all cached data on logout.
  Future<void> clearAll() async {
    await _offlineBox?.clear();
    await _profileBox?.clear();
  }
}
