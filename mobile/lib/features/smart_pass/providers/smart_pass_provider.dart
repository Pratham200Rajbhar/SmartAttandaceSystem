
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/domain/models/smart_pass.dart';
import 'package:smart_attendance_app/utils/logger.dart';

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

  Future<void> generatePass() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _api.getSmartPass();
      if (!mounted) return;
      final pass = SmartPass.fromJson(data);
      state = SmartPassState(pass: pass, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      AppLogger.error('Smart Pass failed: $e');
      state = const SmartPassState(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (mounted) {
        generatePass();
      }
    });
  }

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
