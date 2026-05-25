// Smart Pass provider - manages QR code generation and auto-refresh
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/domain/models/smart_pass.dart';

class SmartPassState {
  final SmartPass? pass;
  final bool isLoading;
  final String? errorMessage;

  const SmartPassState({
    this.pass,
    this.isLoading = false,
    this.errorMessage,
  });

  SmartPassState copyWith({
    SmartPass? pass,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SmartPassState(
      pass: pass ?? this.pass,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class SmartPassNotifier extends StateNotifier<SmartPassState> {
  final StudentApi _api;
  Timer? _refreshTimer;

  SmartPassNotifier(this._api) : super(const SmartPassState());

  /// Generate a new Smart Pass QR code
  Future<void> generatePass() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _api.getSmartPass();
      final pass = SmartPass.fromJson(data);
      state = SmartPassState(pass: pass, isLoading: false);
    } catch (e) {
      debugPrint('Smart Pass generation failed: $e');
      state = SmartPassState(
        isLoading: false,
        errorMessage: 'Failed to generate Smart Pass: $e',
      );
    }
  }

  /// Start auto-refresh timer (every 25 seconds to stay ahead of 30s expiry)
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (mounted) {
        generatePass();
      }
    });
  }

  /// Stop auto-refresh timer
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}

final smartPassProvider =
    StateNotifierProvider.autoDispose<SmartPassNotifier, SmartPassState>((ref) {
  return SmartPassNotifier(ref.read(studentApiProvider));
});
