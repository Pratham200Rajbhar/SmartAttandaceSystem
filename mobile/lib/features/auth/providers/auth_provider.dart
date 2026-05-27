import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/core/exceptions.dart';
import 'package:smart_attendance_app/core/events.dart';
import 'package:smart_attendance_app/data/api/dio_client.dart';
import 'package:smart_attendance_app/data/local/device_service.dart';
import 'package:smart_attendance_app/data/repositories/auth_repository.dart';
import 'package:smart_attendance_app/domain/enums/auth_state.dart';
import 'package:smart_attendance_app/domain/models/user.dart';
import 'package:smart_attendance_app/utils/logger.dart';

class AuthStateData {
  final AuthStatus status;
  final UserProfile? user;
  final String? errorMessage;

  const AuthStateData({
    this.status = AuthStatus.loading,
    this.user,
    this.errorMessage,
  });

  AuthStateData copyWith({AuthStatus? status, UserProfile? user, String? errorMessage}) {
    return AuthStateData(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthStateData> {
  final AuthRepository _repo;
  final DeviceService _deviceService;
  late final StreamSubscription<String> _authErrorSubscription;

  AuthNotifier(this._repo, this._deviceService) : super(const AuthStateData()) {
    _authErrorSubscription = AppEvents.authErrorStream.listen((event) {
      if (event == 'session_expired') {
        logoutWithReason('Session expired. Please log in again.');
      }
    });
  }

  @override
  void dispose() {
    _authErrorSubscription.cancel();
    super.dispose();
  }

  Future<void> checkInitialAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      
      await _deviceService.getDeviceUUID();

      final result = await _repo.checkAuthState();
      state = AuthStateData(status: result.status, user: result.profile);
    } catch (e) {
      AppLogger.error('Auth check failed: $e');
      state = const AuthStateData(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final deviceUuid = await _deviceService.getDeviceUUID();
      final result = await _repo.login(email, password, deviceUuid);
      state = AuthStateData(status: result.status, user: result.profile);
    } on AppException catch (e) {
      AppLogger.error('Login failed: $e');
      state = AuthStateData(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } on DioException catch (e) {
      AppLogger.error('Login failed: $e');
      final mapped = mapDioError(e);
      state = AuthStateData(
        status: AuthStatus.unauthenticated,
        errorMessage: mapped.message,
      );
    } catch (e) {
      AppLogger.error('Login error: $e');
      state = const AuthStateData(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  void onFaceRegistered() {
    state = state.copyWith(status: AuthStatus.authenticated);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthStateData(status: AuthStatus.unauthenticated);
  }

  Future<void> logoutWithReason(String reason) async {
    await logout();
    state = AuthStateData(
      status: AuthStatus.unauthenticated,
      errorMessage: reason,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(deviceServiceProvider),
  );
});
