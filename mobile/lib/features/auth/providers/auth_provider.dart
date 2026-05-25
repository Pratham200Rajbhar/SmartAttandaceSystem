import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/core/events.dart';
import 'package:smart_attendance_app/data/local/device_service.dart';
import 'package:smart_attendance_app/data/repositories/auth_repository.dart';
import 'package:smart_attendance_app/domain/enums/auth_state.dart';
import 'package:smart_attendance_app/domain/models/user.dart';

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
      errorMessage: errorMessage,
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

  /// Called on app start — silently checks JWT validity.
  Future<void> checkInitialAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      // 1. Grab hardware UUID on app launch
      await _deviceService.getDeviceUUID();

      // 2. Check login status
      final result = await _repo.checkAuthState();
      state = AuthStateData(status: result.status, user: result.profile);
    } catch (e, stackTrace) {
      debugPrint('AuthNotifier.checkInitialAuth failed: $e\n$stackTrace');
      state = const AuthStateData(status: AuthStatus.unauthenticated);
    }
  }

  /// Authenticates with email/password.
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final deviceUuid = await _deviceService.getDeviceUUID();
      final result = await _repo.login(email, password, deviceUuid);
      state = AuthStateData(status: result.status, user: result.profile);
    } catch (e, stackTrace) {
      debugPrint('AuthNotifier.login error: $e\n$stackTrace');
      state = AuthStateData(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  /// Marks face registration as complete — transitions to authenticated.
  void onFaceRegistered() {
    state = state.copyWith(status: AuthStatus.authenticated);
  }

  /// Clears auth state and logs out.
  Future<void> logout() async {
    await _repo.logout();
    state = const AuthStateData(status: AuthStatus.unauthenticated);
  }

  /// Clears auth state and logs out with a custom error message displayed to the user.
  Future<void> logoutWithReason(String reason) async {
    await _repo.logout();
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
