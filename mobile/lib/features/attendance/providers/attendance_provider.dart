
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/core/exceptions.dart';
import 'package:smart_attendance_app/data/repositories/attendance_repository.dart';
import 'package:smart_attendance_app/utils/logger.dart';

enum VerificationStep { gps, camera, preview, submitting, done }

class AttendanceVerificationState {
  final VerificationStep step;
  final double? latitude;
  final double? longitude;
  final String? imagePath;
  final AttendanceSubmitResult? result;
  final String? errorMessage;
  final bool isError;

  const AttendanceVerificationState({
    this.step = VerificationStep.gps,
    this.latitude,
    this.longitude,
    this.imagePath,
    this.result,
    this.errorMessage,
    this.isError = false,
  });

  AttendanceVerificationState copyWith({
    VerificationStep? step,
    double? latitude,
    double? longitude,
    String? imagePath,
    AttendanceSubmitResult? result,
    String? errorMessage,
    bool? isError,
  }) {
    return AttendanceVerificationState(
      step: step ?? this.step,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imagePath: imagePath ?? this.imagePath,
      result: result ?? this.result,
      errorMessage: errorMessage,
      isError: isError ?? this.isError,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceVerificationState> {
  final AttendanceRepository _repo;
  String? _lastSubmittedSessionId;

  String? get lastSubmittedSessionId => _lastSubmittedSessionId;

  AttendanceNotifier(this._repo) : super(const AttendanceVerificationState());

  void setGpsLocation(double lat, double lng) {
    state = state.copyWith(
        latitude: lat, longitude: lng, step: VerificationStep.camera);
  }

  void setImagePath(String path) {
    state = state.copyWith(imagePath: path, step: VerificationStep.preview);
  }

  void confirmSubmit() {
    state = state.copyWith(step: VerificationStep.submitting);
  }

  Future<void> submit(String sessionId) async {
    if (state.latitude == null ||
        state.longitude == null ||
        state.imagePath == null) {
      state = state.copyWith(
        errorMessage: 'Missing GPS or image data',
        isError: true,
      );
      return;
    }

    try {
      final result = await _repo.submitAttendance(
        sessionId: sessionId,
        latitude: state.latitude!,
        longitude: state.longitude!,
        imagePath: state.imagePath!,
      );
      _lastSubmittedSessionId = sessionId;
      state = state.copyWith(result: result, step: VerificationStep.done);
    } catch (e) {
      AppLogger.error('Attendance submit failed: $e');
      final displayError = e is AppException ? e.message : 'Something went wrong. Please try again.';
      state = state.copyWith(
        errorMessage: displayError,
        isError: true,
        step: VerificationStep.done,
      );
    }
  }

  void reset() {
    _lastSubmittedSessionId = null;
    state = const AttendanceVerificationState();
  }
}

final attendanceVerificationProvider = StateNotifierProvider<
    AttendanceNotifier, AttendanceVerificationState>((ref) {
  return AttendanceNotifier(ref.read(attendanceRepositoryProvider));
});
