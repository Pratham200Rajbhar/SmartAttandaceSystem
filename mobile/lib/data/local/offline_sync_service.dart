
library;

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/core/constants.dart';
import 'package:smart_attendance_app/data/api/dio_client.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/data/local/hive_service.dart';
import 'package:smart_attendance_app/data/local/notification_service.dart';

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(
    studentApi: ref.read(studentApiProvider),
    hive: ref.read(hiveServiceProvider),
    notificationService: ref.read(notificationServiceProvider),
    notificationsNotifier: ref.read(notificationsProvider.notifier),
    dio: ref.read(dioProvider),
  );
});

class OfflineSyncService {
  final StudentApi _studentApi;
  final HiveService _hive;
  final NotificationService _notificationService;
  final NotificationsNotifier _notificationsNotifier;
  final Dio _dio;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;

  OfflineSyncService({
    required StudentApi studentApi,
    required HiveService hive,
    required NotificationService notificationService,
    required NotificationsNotifier notificationsNotifier,
    required Dio dio,
  })  : _studentApi = studentApi,
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

  Future<int> syncQueue() async {
    if (_isSyncing) return 0;

    final queue = _hive.getQueue();
    if (queue.isEmpty) return 0;

    try {
      final response = await _dio.get<Map<String, dynamic>>('/health');
      if (response.statusCode != 200 || response.data?['status'] != 'healthy') {
        debugPrint('OfflineSyncService: Backend health check failed or returned unhealthy.');
        return 0;
      }
    } catch (e) {
      debugPrint('OfflineSyncService: Backend health check ping failed (true offline). Error: $e');
      return 0;
    }

    _isSyncing = true;

    int syncedCount = 0;
    try {
      for (final payload in queue) {
        
        final age = DateTime.now().difference(payload.capturedAt);
        if (age > kOfflinePayloadMaxAge) {
          await _removePayload(payload);
          await _deleteImageFile(payload.imagePath);
          await _notificationService.addNotification(
            title: 'Submission Expired',
            body:
                'Attendance for ${payload.className ?? 'a class'} was captured ${age.inMinutes} minutes ago and has expired.',
            severity: 'warning',
          );
          continue;
        }

        try {
          await _studentApi.markAttendance(
            sessionId: payload.sessionId,
            latitude: payload.latitude,
            longitude: payload.longitude,
            imagePath: payload.imagePath,
          );
          
          await _removePayload(payload);
          await _deleteImageFile(payload.imagePath);
          await _notificationService.addNotification(
            title: 'Offline Sync Complete',
            body:
                'Successfully synced offline attendance for ${payload.className ?? 'a class'}.',
            severity: 'success',
          );
          syncedCount++;
        } on DioException catch (e) {
          final statusCode = e.response?.statusCode ?? 0;
          final isClientError = statusCode >= 400 && statusCode < 500;

          if (isClientError) {
            
            await _removePayload(payload);
            await _deleteImageFile(payload.imagePath);
            await _notificationService.addNotification(
              title: 'Submission Rejected',
              body:
                  'Attendance for ${payload.className ?? 'a class'} was rejected by the server ($statusCode).',
              severity: 'danger',
            );
            continue;
          }

          debugPrint('OfflineSyncService sync failed (5xx/network): $e');
          await _notificationService.addNotification(
            title: 'Sync Failed',
            body:
                'Could not sync attendance for ${payload.className ?? 'a class'}. Will retry automatically.',
            severity: 'warning',
          );
          break;
        } catch (e, stackTrace) {
          debugPrint('OfflineSyncService sync failed: $e\n$stackTrace');
          await _notificationService.addNotification(
            title: 'Sync Failed',
            body:
                'Could not sync attendance for ${payload.className ?? 'a class'}. Will retry automatically.',
            severity: 'warning',
          );
          break;
        }
      }
    } finally {
      _isSyncing = false;
      
      if (syncedCount > 0) {
        await _notificationsNotifier.load();
      }
    }
    return syncedCount;
  }

  Future<void> _removePayload(dynamic payload) async {
    final key = payload.key;
    if (key != null && key is int) {
      await _hive.removeFromQueue(key);
    }
  }

  Future<void> _deleteImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('OfflineSyncService: Failed to delete image file $imagePath: $e');
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}
