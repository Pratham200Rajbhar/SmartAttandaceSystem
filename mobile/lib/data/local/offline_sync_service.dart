
library;

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/core/constants.dart';
import 'package:smart_attendance_app/core/attendance_constants.dart';
import 'package:smart_attendance_app/data/api/dio_client.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/domain/models/offline_payload.dart';
import 'package:smart_attendance_app/data/local/hive_service.dart';
import 'package:smart_attendance_app/data/local/notification_service.dart';
import 'package:smart_attendance_app/data/local/pending_count_provider.dart';
import 'package:smart_attendance_app/utils/logger.dart';

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(
    ref: ref,
    studentApi: ref.read(studentApiProvider),
    hive: ref.read(hiveServiceProvider),
    notificationService: ref.read(notificationServiceProvider),
    notificationsNotifier: ref.read(notificationsProvider.notifier),
    dio: ref.read(dioProvider),
  );
});

class OfflineSyncService {
  final Ref _ref;
  final StudentApi _studentApi;
  final HiveService _hive;
  final NotificationService _notificationService;
  final NotificationsNotifier _notificationsNotifier;
  final Dio _dio;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;

  OfflineSyncService({
    required Ref ref,
    required StudentApi studentApi,
    required HiveService hive,
    required NotificationService notificationService,
    required NotificationsNotifier notificationsNotifier,
    required Dio dio,
  })  : _ref = ref,
        _studentApi = studentApi,
        _hive = hive,
        _notificationService = notificationService,
        _notificationsNotifier = notificationsNotifier,
        _dio = dio;

  void startListening() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        syncQueue();
      }
    });
  }

  String _className(OfflineAttendancePayload p) => p.className ?? 'a class';

  Future<void> _notify(String title, String body, String severity) =>
      _notificationService.addNotification(title: title, body: body, severity: severity);

  Future<void> _removePayload(dynamic payload) async {
    final key = payload.key;
    if (key != null && key is int) {
      await _hive.removeFromQueue(key);
      _ref.read(pendingCountProvider.notifier).refresh();
    }
  }

  Future<void> _deleteImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<int> syncQueue() async {
    if (_isSyncing) return 0;

    final queue = _hive.getQueue();
    if (queue.isEmpty) return 0;

    try {
      final response = await _dio.get<Map<String, dynamic>>('/health');
      if (response.statusCode != 200 || response.data?['status'] != 'healthy') return 0;
    } catch (_) {
      return 0;
    }

    _isSyncing = true;
    int syncedCount = 0;

    try {
      for (final payload in queue) {
        if (await _processPayload(payload)) syncedCount++;
      }
    } finally {
      _isSyncing = false;
      if (syncedCount > 0) await _notificationsNotifier.load();
    }
    return syncedCount;
  }

  Future<bool> _processPayload(OfflineAttendancePayload payload) async {
    final age = DateTime.now().difference(payload.capturedAt);

    if (age > kOfflinePayloadMaxAge) {
      await _removePayload(payload);
      await _deleteImageFile(payload.imagePath);
      await _notify('Submission Expired',
          'Attendance for ${_className(payload)} was captured ${age.inMinutes} minutes ago and has expired.',
          kSeverityWarning);
      return false;
    }

    try {
      await _studentApi.markAttendance(
        sessionId: payload.sessionId,
        latitude: payload.latitude,
        longitude: payload.longitude,
        accuracy: payload.accuracy ?? 0.0,
        imagePath: payload.imagePath,
      );
      await _removePayload(payload);
      await _deleteImageFile(payload.imagePath);
      await _notify('Offline Sync Complete',
          'Successfully synced offline attendance for ${_className(payload)}.',
          kSeveritySuccess);
      return true;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode >= 400 && statusCode < 500) {
        await _removePayload(payload);
        await _deleteImageFile(payload.imagePath);
        await _notify('Submission Rejected',
            'Attendance for ${_className(payload)} was rejected by the server ($statusCode).',
            kSeverityDanger);
        return false;
      }
      _handleSyncError(payload);
      return false;
    } catch (e) {
      AppLogger.error('Sync failed: $e');
      _handleSyncError(payload);
      return false;
    }
  }

  Future<void> _handleSyncError(OfflineAttendancePayload payload) async {
    AppLogger.error('Sync failed for ${_className(payload)}');
    await _notify('Sync Failed',
        'Could not sync attendance for ${_className(payload)}. Will retry automatically.',
        kSeverityWarning);
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}
