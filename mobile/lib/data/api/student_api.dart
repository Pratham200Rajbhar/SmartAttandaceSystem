// Student feature API client.
// Handles face registration, attendance marking, and history retrieval.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:smart_attendance_app/data/api/dio_client.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';

final studentApiProvider = Provider<StudentApi>((ref) {
  return StudentApi(ref.read(dioProvider));
});

class StudentApi {
  final Dio _dio;

  const StudentApi(this._dio);

  /// Uploads a selfie for face embedding registration.
  /// Backend runs DeepFace and stores the 128-d vector permanently.
  Future<void> registerFace(String imagePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imagePath,
        contentType: MediaType('image', 'jpeg'),
      ),
    });
    await _dio.post<void>('/student/register-face', data: formData);
  }

  /// Submits an attendance verification attempt with GPS + selfie.
  /// Returns the AI composite scoring result.
  Future<AttendanceResult> markAttendance({
    required String sessionId,
    required double latitude,
    required double longitude,
    required String imagePath,
  }) async {
    final formData = FormData.fromMap({
      'session_id': sessionId,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'image': await MultipartFile.fromFile(
        imagePath,
        contentType: MediaType('image', 'jpeg'),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/student/attendance/mark',
      data: formData,
    );
    return AttendanceResult.fromJson(response.data!);
  }

  /// Retrieves the student's full attendance history with overall percentage.
  Future<AttendanceHistoryResponse> getMyAttendance() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/student/my-attendance');
    return AttendanceHistoryResponse.fromJson(response.data!);
  }

  /// Retrieves the student's enrolled classes and their active sessions.
  Future<List<StudentClass>> getMyClasses() async {
    final response = await _dio.get<List<dynamic>>('/student/classes');
    return response.data!
        .map((e) => StudentClass.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Registers the FCM device token with the backend for push notifications.
  Future<void> registerFcmToken(String token) async {
    await _dio.post<void>(
      '/student/fcm-token',
      data: {'token': token},
    );
  }

  /// Submits a student note on a flagged attendance record.
  Future<void> submitFlaggedNote(String attendanceId, String note) async {
    await _dio.post<void>(
      '/student/attendance/$attendanceId/note',
      data: {'note': note},
    );
  }

  /// Submit a dispute for a flagged or absent attendance record.
  Future<void> submitDispute({
    required String attendanceId,
    required String reason,
    String? proofImagePath,
  }) async {
    final formData = FormData.fromMap({
      'reason': reason,
      if (proofImagePath != null)
        'proof_image': await MultipartFile.fromFile(
          proofImagePath,
          contentType: MediaType('image', 'jpeg'),
        ),
    });
    await _dio.post<void>(
      '/student/attendance/$attendanceId/dispute',
      data: formData,
    );
  }

  /// Get all leave requests for the current student.
  Future<Map<String, dynamic>> getMyLeaves() async {
    final response = await _dio.get<Map<String, dynamic>>('/student/leaves');
    return response.data!;
  }

  /// Create a new leave request.
  Future<Map<String, dynamic>> createLeaveRequest({
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? documentPath,
  }) async {
    final formData = FormData.fromMap({
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'reason': reason,
      if (documentPath != null)
        'document': await MultipartFile.fromFile(
          documentPath,
          contentType: MediaType('image', 'jpeg'),
        ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/student/leaves',
      data: formData,
    );
    return response.data!;
  }

  /// Generate a time-limited Smart Pass QR code token.
  Future<Map<String, dynamic>> getSmartPass() async {
    final response = await _dio.get<Map<String, dynamic>>('/student/smart-pass');
    return response.data!;
  }

  /// Get comprehensive gamification and analytics stats.
  Future<Map<String, dynamic>> getMyStats() async {
    final response = await _dio.get<Map<String, dynamic>>('/student/stats');
    return response.data!;
  }
}
