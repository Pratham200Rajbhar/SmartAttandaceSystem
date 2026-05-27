
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:smart_attendance_app/data/api/dio_client.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/domain/models/leaderboard.dart';

final studentApiProvider = Provider<StudentApi>((ref) {
  return StudentApi(ref.read(dioProvider));
});

class StudentApi {
  final Dio _dio;

  const StudentApi(this._dio);

  Future<void> registerFace(String imagePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imagePath,
        contentType: MediaType('image', 'jpeg'),
      ),
    });
    await _dio.post<void>('/student/register-face', data: formData);
  }

  Future<AttendanceResult> markAttendance({
    required String sessionId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String imagePath,
  }) async {
    final Map<String, dynamic> formDataMap = {
      'session_id': sessionId,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'accuracy': accuracy.toString(),
    };
    
    if (File(imagePath).existsSync()) {
      formDataMap['image'] = await MultipartFile.fromFile(
        imagePath,
        contentType: MediaType('image', 'jpeg'),
      );
    }
    
    final formData = FormData.fromMap(formDataMap);
    final response = await _dio.post<Map<String, dynamic>>(
      '/student/attendance/mark',
      data: formData,
    );
    return AttendanceResult.fromJson(response.data!);
  }

  Future<AttendanceAnalysisResult> analyzeAttendance({
    required String sessionId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String imagePath,
  }) async {
    final Map<String, dynamic> formDataMap = {
      'session_id': sessionId,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'accuracy': accuracy.toString(),
    };
    
    if (File(imagePath).existsSync()) {
      formDataMap['image'] = await MultipartFile.fromFile(
        imagePath,
        contentType: MediaType('image', 'jpeg'),
      );
    }

    final formData = FormData.fromMap(formDataMap);
    final response = await _dio.post<Map<String, dynamic>>(
      '/student/attendance/analyze',
      data: formData,
    );
    return AttendanceAnalysisResult.fromJson(response.data!);
  }

  Future<AttendanceResult> confirmAttendance({
    required String reviewToken,
  }) async {
    final formData = FormData.fromMap({
      'review_token': reviewToken,
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/student/attendance/confirm',
      data: formData,
    );
    return AttendanceResult.fromJson(response.data!);
  }

  Future<AttendanceHistoryResponse> getMyAttendance() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/student/my-attendance');
    return AttendanceHistoryResponse.fromJson(response.data!);
  }

  Future<List<StudentClass>> getMyClasses() async {
    final response = await _dio.get<List<dynamic>>('/student/classes');
    return response.data!
        .map((e) => StudentClass.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> registerFcmToken(String token) async {
    await _dio.post<void>(
      '/student/fcm-token',
      data: {'token': token},
    );
  }

  Future<void> submitFlaggedNote(String attendanceId, String note) async {
    await _dio.post<void>(
      '/student/attendance/$attendanceId/note',
      data: {'note': note},
    );
  }

  Future<Map<String, dynamic>> getMyLeaves() async {
    final response = await _dio.get<Map<String, dynamic>>('/student/leaves');
    return response.data!;
  }

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

  Future<Map<String, dynamic>> getSmartPass() async {
    final response = await _dio.get<Map<String, dynamic>>('/student/smart-pass');
    return response.data!;
  }

  Future<Map<String, dynamic>> getMyStats() async {
    final response = await _dio.get<Map<String, dynamic>>('/student/stats');
    return response.data!;
  }

  Future<LeaderboardResponse> getLeaderboard() async {
    final response = await _dio.get<Map<String, dynamic>>('/student/leaderboard');
    return LeaderboardResponse.fromJson(response.data!);
  }
}
