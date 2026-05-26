
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/data/repositories/attendance_repository.dart';
import 'package:smart_attendance_app/utils/logger.dart';

enum RegistrationStatus { idle, capturing, uploading, success, error }

class RegistrationState {
  final RegistrationStatus status;
  final String? errorMessage;

  const RegistrationState({this.status = RegistrationStatus.idle, this.errorMessage});

  RegistrationState copyWith({RegistrationStatus? status, String? errorMessage}) {
    return RegistrationState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  final AttendanceRepository _repo;

  RegistrationNotifier(this._repo) : super(const RegistrationState());

  void startCapture() {
    state = state.copyWith(status: RegistrationStatus.capturing);
  }

  Future<bool> uploadFace(String imagePath) async {
    state = state.copyWith(status: RegistrationStatus.uploading, errorMessage: null);
    try {
      await _repo.registerFace(imagePath);
      state = state.copyWith(status: RegistrationStatus.success);
      return true;
    } catch (e) {
      AppLogger.error('Face upload failed: $e');
      state = RegistrationState(
        status: RegistrationStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = const RegistrationState();
  }
}

final registrationProvider =
    StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  return RegistrationNotifier(ref.read(attendanceRepositoryProvider));
});
