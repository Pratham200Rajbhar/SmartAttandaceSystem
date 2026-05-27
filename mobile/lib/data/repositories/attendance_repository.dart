
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
import 'package:smart_attendance_app/data/local/pending_count_provider.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/domain/models/offline_payload.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(
    ref: ref,
    studentApi: ref.read(studentApiProvider),
    hive: ref.read(hiveServiceProvider),
  );
});

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
  final Ref _ref;
  final StudentApi _studentApi;
  final HiveService _hive;

  const AttendanceRepository({
    required Ref ref,
    required StudentApi studentApi,
    required HiveService hive,
  })  : _ref = ref,
        _studentApi = studentApi,
        _hive = hive;

  Future<AttendanceSubmitResult> submitAttendance({
    required String sessionId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String imagePath,
    String? className,
  }) async {
    
    final savedImagePath = await _saveImageToAppDocs(imagePath);

    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity.any((c) => c != ConnectivityResult.none);

    if (isOnline) {
      try {
        final result = await _studentApi.markAttendance(
          sessionId: sessionId,
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          imagePath: savedImagePath,
        );
        return OnlineResult(result);
      } on DioException catch (e) {
        
        final isNetworkError = [
          DioExceptionType.connectionTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.connectionError,
        ].contains(e.type);
        
        final isServerError = e.response != null && e.response!.statusCode! >= 500;

        if (!isNetworkError && !isServerError) {
          throw mapDioError(e); 
        }
      }
    }

    final payload = OfflineAttendancePayload(
      sessionId: sessionId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      imagePath: savedImagePath,
      capturedAt: DateTime.now(),
      className: className,
    );
    await _hive.addToQueue(payload);
    _ref.read(pendingCountProvider.notifier).refresh();
    return OfflineQueued(_hive.pendingCount);
  }

  /// Analyze attendance (AI scoring) without saving the record.
  /// Returns scores + a review token for confirmation.
  Future<AttendanceAnalysisResult> analyzeAttendance({
    required String sessionId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String imagePath,
  }) async {
    final savedImagePath = await _saveImageToAppDocs(imagePath);
    try {
      return await _studentApi.analyzeAttendance(
        sessionId: sessionId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        imagePath: savedImagePath,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Confirm a previously analyzed attendance using its review token.
  Future<AttendanceSubmitResult> confirmAttendance({
    required String reviewToken,
    required String sessionId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String imagePath,
    String? className,
  }) async {
    final savedImagePath = await _saveImageToAppDocs(imagePath);

    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity.any((c) => c != ConnectivityResult.none);

    if (isOnline) {
      try {
        final result = await _studentApi.confirmAttendance(reviewToken: reviewToken);
        return OnlineResult(result);
      } on DioException catch (e) {
        final isNetworkError = [
          DioExceptionType.connectionTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.connectionError,
        ].contains(e.type);
        final isServerError = e.response != null && e.response!.statusCode! >= 500;
        if (!isNetworkError && !isServerError) {
          throw mapDioError(e);
        }
      }
    }

    // Offline fallback — queue the original payload
    final payload = OfflineAttendancePayload(
      sessionId: sessionId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      imagePath: savedImagePath,
      capturedAt: DateTime.now(),
      className: className,
    );
    await _hive.addToQueue(payload);
    _ref.read(pendingCountProvider.notifier).refresh();
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

  Future<void> registerFace(String imagePath) => _studentApi.registerFace(imagePath);

  Future<AttendanceHistoryResponse> getHistory() => _studentApi.getMyAttendance();

  int get pendingOfflineCount => _hive.pendingCount;
}
