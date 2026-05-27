
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/core/exceptions.dart';
import 'package:smart_attendance_app/data/repositories/attendance_repository.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/utils/logger.dart';

enum VerificationStep { gps, camera, preview, submitting, reviewing, confirming, done }

class AttendanceVerificationState {
  final VerificationStep step;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? imagePath;
  final AttendanceAnalysisResult? analysisResult;
  final AttendanceSubmitResult? result;
  final String? errorMessage;
  final bool isError;

  const AttendanceVerificationState({
    this.step = VerificationStep.gps,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.imagePath,
    this.analysisResult,
    this.result,
    this.errorMessage,
    this.isError = false,
  });

  AttendanceVerificationState copyWith({
    VerificationStep? step,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? imagePath,
    AttendanceAnalysisResult? analysisResult,
    AttendanceSubmitResult? result,
    String? errorMessage,
    bool? isError,
  }) {
    return AttendanceVerificationState(
      step: step ?? this.step,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      imagePath: imagePath ?? this.imagePath,
      analysisResult: analysisResult ?? this.analysisResult,
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

  void setGpsLocation(double lat, double lng, double accuracy) {
    state = state.copyWith(
        latitude: lat,
        longitude: lng,
        accuracy: accuracy,
        step: VerificationStep.camera);
  }

  void setImagePath(String path) {
    state = state.copyWith(imagePath: path, step: VerificationStep.preview);
  }

  /// Kick off AI analysis — moves to [VerificationStep.submitting] while
  /// waiting, then to [VerificationStep.reviewing] on success.
  Future<void> analyze(String sessionId) async {
    if (state.latitude == null ||
        state.longitude == null ||
        state.accuracy == null ||
        state.imagePath == null) {
      state = state.copyWith(
        errorMessage: 'Missing GPS or image data',
        isError: true,
      );
      return;
    }

    state = state.copyWith(step: VerificationStep.submitting);

    try {
      final analysis = await _repo.analyzeAttendance(
        sessionId: sessionId,
        latitude: state.latitude!,
        longitude: state.longitude!,
        accuracy: state.accuracy!,
        imagePath: state.imagePath!,
      );
      state = state.copyWith(
        analysisResult: analysis,
        step: VerificationStep.reviewing,
      );
    } catch (e) {
      AppLogger.error('Attendance analyze failed: $e');
      final displayError =
          e is AppException ? e.message : 'Something went wrong. Please try again.';
      state = state.copyWith(
        errorMessage: displayError,
        isError: true,
        step: VerificationStep.done,
      );
    }
  }

  /// Confirm the reviewed submission — saves the attendance record.
  Future<void> confirm(String sessionId) async {
    final analysis = state.analysisResult;
    if (analysis == null) {
      state = state.copyWith(
        errorMessage: 'No analysis result to confirm',
        isError: true,
        step: VerificationStep.done,
      );
      return;
    }

    state = state.copyWith(step: VerificationStep.confirming);

    try {
      final result = await _repo.confirmAttendance(
        reviewToken: analysis.reviewToken,
        sessionId: sessionId,
        latitude: state.latitude!,
        longitude: state.longitude!,
        accuracy: state.accuracy!,
        imagePath: state.imagePath!,
      );
      _lastSubmittedSessionId = sessionId;
      state = state.copyWith(result: result, step: VerificationStep.done);
    } catch (e) {
      AppLogger.error('Attendance confirm failed: $e');
      final displayError =
          e is AppException ? e.message : 'Something went wrong. Please try again.';
      state = state.copyWith(
        errorMessage: displayError,
        isError: true,
        step: VerificationStep.done,
      );
    }
  }

  /// Legacy direct-submit path (used for offline queue fallback).
  Future<void> submit(String sessionId) async {
    if (state.latitude == null ||
        state.longitude == null ||
        state.accuracy == null ||
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
        accuracy: state.accuracy!,
        imagePath: state.imagePath!,
      );
      _lastSubmittedSessionId = sessionId;
      state = state.copyWith(result: result, step: VerificationStep.done);
    } catch (e) {
      AppLogger.error('Attendance submit failed: $e');
      final displayError =
          e is AppException ? e.message : 'Something went wrong. Please try again.';
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
