// Attendance repository — handles online submission and offline queue fallback.
// Checks connectivity before deciding the submission path.
library;

import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:smart_attendance_app/data/api/dio_client.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/data/local/hive_service.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/domain/models/offline_payload.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(
    studentApi: ref.read(studentApiProvider),
    hive: ref.read(hiveServiceProvider),
  );
});

/// Result of an attendance submission attempt.
/// Either an online result or an offline queue confirmation.
sealed class AttendanceSubmitResult {}

class OnlineResult extends AttendanceSubmitResult {
  final AttendanceResult result;
  OnlineResult(this.result);
}

class OfflineQueued extends AttendanceSubmitResult {
  final int queuePosition;
  OfflineQueued(this.queuePosition);
}

class AttendanceRepository {
  final StudentApi _studentApi;
  final HiveService _hive;

  const AttendanceRepository({
    required StudentApi studentApi,
    required HiveService hive,
  })  : _studentApi = studentApi,
        _hive = hive;

  /// Submits attendance — online if connected, queues to Hive if offline.
  Future<AttendanceSubmitResult> submitAttendance({
    required String sessionId,
    required double latitude,
    required double longitude,
    required String imagePath,
    String? className,
  }) async {
    // 1. First, save the image safely to app docs to prevent cache purges
    final savedImagePath = await _saveImageToAppDocs(imagePath);

    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity.any((c) => c != ConnectivityResult.none);

    if (isOnline) {
      try {
        final result = await _studentApi.markAttendance(
          sessionId: sessionId,
          latitude: latitude,
          longitude: longitude,
          imagePath: savedImagePath,
        );
        return OnlineResult(result);
      } on DioException catch (e) {
        // Fall back to offline queue for network timeouts or 5xx server errors
        final isNetworkError = [
          DioExceptionType.connectionTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.connectionError,
        ].contains(e.type);
        
        final isServerError = e.response != null && e.response!.statusCode! >= 500;

        if (!isNetworkError && !isServerError) {
          throw mapDioError(e); // Propagate 4xx errors (e.g. Auth/Validation)
        }
      }
    }

    // Offline path: queue for later sync
    final payload = OfflineAttendancePayload(
      sessionId: sessionId,
      latitude: latitude,
      longitude: longitude,
      imagePath: savedImagePath,
      capturedAt: DateTime.now(),
      className: className,
    );
    await _hive.addToQueue(payload);
    return OfflineQueued(_hive.pendingCount);
  }

  Future<String> _saveImageToAppDocs(String tempPath) async {
    try {
      final file = File(tempPath);
      if (!await file.exists()) return tempPath;
      final dir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(tempPath);
      final savedImage = await file.copy(p.join(dir.path, fileName));
      return savedImage.path;
    } catch (e) {
      return tempPath;
    }
  }

  /// Uploads a face registration selfie.
  Future<void> registerFace(String imagePath) async {
    try {
      await _studentApi.registerFace(imagePath);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Fetches full attendance history from backend.
  Future<AttendanceHistoryResponse> getHistory() async {
    try {
      return await _studentApi.getMyAttendance();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Returns the count of pending offline submissions.
  int get pendingOfflineCount => _hive.pendingCount;
}
