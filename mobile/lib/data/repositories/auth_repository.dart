
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/core/exceptions.dart';
import 'package:smart_attendance_app/data/api/auth_api.dart';
import 'package:smart_attendance_app/data/api/dio_client.dart';
import 'package:smart_attendance_app/data/local/hive_service.dart';
import 'package:smart_attendance_app/data/local/secure_storage.dart';
import 'package:smart_attendance_app/domain/enums/auth_state.dart';
import 'package:smart_attendance_app/domain/models/user.dart';
import 'package:smart_attendance_app/utils/logger.dart';

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

  AuthStatus _computeAuthStatus(UserProfile profile) {
    final needsRegistration =
        profile.studentProfile == null || !profile.hasFaceRegistered;
    return needsRegistration
        ? AuthStatus.registrationRequired
        : AuthStatus.authenticated;
  }

  Future<({UserProfile profile, AuthStatus status})> login(
    String email,
    String password,
    String deviceUuid,
  ) async {
    try {
      final tokenResponse = await _authApi.login(
        email, password, deviceUuid: deviceUuid,
      );

      if (tokenResponse.role != 'STUDENT') {
        throw const AuthException(
          'This app is for students only. Use the web dashboard for teacher/admin access.',
        );
      }

      await _storage.saveToken(tokenResponse.accessToken);
      await _storage.saveUserRole(tokenResponse.role);

      final profile = await _authApi.getProfile();
      await _hive.cacheProfile(profile);

      return (profile: profile, status: _computeAuthStatus(profile));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<({UserProfile? profile, AuthStatus status})> checkAuthState() async {
    final token = await _storage.getToken();
    if (token == null) {
      return (profile: null, status: AuthStatus.unauthenticated);
    }

    try {
      final profile = await _authApi.getProfile();
      await _hive.cacheProfile(profile);

      return (profile: profile, status: _computeAuthStatus(profile));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.clearAll();
        return (profile: null, status: AuthStatus.unauthenticated);
      }
      
      final cached = _hive.getCachedProfile();
      if (cached != null) {
        return (profile: cached, status: AuthStatus.authenticated);
      }
      return (profile: null, status: AuthStatus.unauthenticated);
    }
  }

  Future<void> logout() async {
    try {
      await _authApi.logout();
    } on DioException catch (e) {
      AppLogger.warn('Logout API call failed', context: {'error': e.toString()});
    }
    await _storage.clearAll();
    await _hive.clearAll();
  }

  UserProfile? getCachedProfile() => _hive.getCachedProfile();
}
