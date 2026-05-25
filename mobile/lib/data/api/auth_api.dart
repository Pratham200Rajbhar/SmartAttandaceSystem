// Authentication API client.
// Handles login, profile fetch, and logout calls against the FastAPI backend.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/data/api/dio_client.dart';
import 'package:smart_attendance_app/domain/models/user.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.read(dioProvider));
});

class AuthApi {
  final Dio _dio;

  const AuthApi(this._dio);

  /// Authenticates with email/password and returns a JWT token response.
  Future<TokenResponse> login(String email, String password, {String? deviceUuid}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        if (deviceUuid != null) 'device_uuid': deviceUuid,
      },
    );
    return TokenResponse.fromJson(response.data!);
  }

  /// Fetches the authenticated user's profile including student details.
  Future<UserProfile> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    return UserProfile.fromJson(response.data!);
  }

  /// Revokes the current JWT on the server-side Redis denylist.
  Future<void> logout() async {
    await _dio.post<void>('/auth/logout');
  }

  /// Requests the backend to unbind the device from the student's account.
  Future<void> requestDeviceReset() async {
    await _dio.post<void>('/auth/request-device-reset');
  }
}
