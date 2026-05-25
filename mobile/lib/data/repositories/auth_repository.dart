// Auth repository — orchestrates API calls with local secure storage.
// Single source of truth for authentication state transitions.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/core/exceptions.dart';
import 'package:smart_attendance_app/data/api/auth_api.dart';
import 'package:smart_attendance_app/data/api/dio_client.dart';
import 'package:smart_attendance_app/data/local/hive_service.dart';
import 'package:smart_attendance_app/data/local/secure_storage.dart';
import 'package:smart_attendance_app/domain/enums/auth_state.dart';
import 'package:smart_attendance_app/domain/models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authApi: ref.read(authApiProvider),
    storage: ref.read(secureStorageProvider),
    hive: ref.read(hiveServiceProvider),
  );
});

class AuthRepository {
  final AuthApi _authApi;
  final SecureStorageService _storage;
  final HiveService _hive;

  const AuthRepository({
    required AuthApi authApi,
    required SecureStorageService storage,
    required HiveService hive,
  })  : _authApi = authApi,
        _storage = storage,
        _hive = hive;

  /// Full login flow: authenticate → store JWT → fetch profile → determine next state.
  Future<({UserProfile profile, AuthStatus status})> login(
    String email,
    String password,
    String deviceUuid,
  ) async {
    try {
      final tokenResponse = await _authApi.login(email, password, deviceUuid: deviceUuid);

      if (tokenResponse.role != 'STUDENT') {
        throw const AuthException(
          'This app is for students only. Use the web dashboard for teacher/admin access.',
        );
      }

      await _storage.saveToken(tokenResponse.accessToken);
      await _storage.saveUserRole(tokenResponse.role);

      final profile = await _authApi.getProfile();
      await _hive.cacheProfile(profile);

      // If student has no face embedding, force registration
      final needsRegistration = profile.studentProfile == null || !profile.hasFaceRegistered;
      final status = needsRegistration
          ? AuthStatus.registrationRequired
          : AuthStatus.authenticated;

      return (profile: profile, status: status);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Checks stored JWT validity by fetching /me.
  /// Returns the current auth status without re-authenticating.
  Future<({UserProfile? profile, AuthStatus status})> checkAuthState() async {
    final token = await _storage.getToken();
    if (token == null) {
      return (profile: null, status: AuthStatus.unauthenticated);
    }

    try {
      final profile = await _authApi.getProfile();
      await _hive.cacheProfile(profile);

      final needsRegistration = profile.studentProfile == null || !profile.hasFaceRegistered;
      final status = needsRegistration
          ? AuthStatus.registrationRequired
          : AuthStatus.authenticated;

      return (profile: profile, status: status);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.clearAll();
        return (profile: null, status: AuthStatus.unauthenticated);
      }
      // Network error — try cached profile for offline access
      final cached = _hive.getCachedProfile();
      if (cached != null) {
        return (profile: cached, status: AuthStatus.authenticated);
      }
      return (profile: null, status: AuthStatus.unauthenticated);
    }
  }

  /// Server-side logout + local credential wipe.
  Future<void> logout() async {
    try {
      await _authApi.logout();
    } on DioException {
      // Proceed with local cleanup even if server call fails
    }
    await _storage.clearAll();
    await _hive.clearAll();
  }

  /// Returns the cached profile without a network call.
  UserProfile? getCachedProfile() => _hive.getCachedProfile();
}
