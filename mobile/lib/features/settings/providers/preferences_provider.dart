
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/data/local/preferences_service.dart';

class PreferencesState {
  final double attendanceTarget;
  final bool notifyClassStart;
  final bool notifyWindowOpen;
  final bool notifySyncDone;
  final bool notifyLowAttendance;
  final double lowAttendanceThreshold;
  final bool isLoading;

  const PreferencesState({
    this.attendanceTarget = 75.0,
    this.notifyClassStart = true,
    this.notifyWindowOpen = true,
    this.notifySyncDone = true,
    this.notifyLowAttendance = true,
    this.lowAttendanceThreshold = 75.0,
    this.isLoading = false,
  });

  PreferencesState copyWith({
    double? attendanceTarget,
    bool? notifyClassStart,
    bool? notifyWindowOpen,
    bool? notifySyncDone,
    bool? notifyLowAttendance,
    double? lowAttendanceThreshold,
    bool? isLoading,
  }) {
    return PreferencesState(
      attendanceTarget: attendanceTarget ?? this.attendanceTarget,
      notifyClassStart: notifyClassStart ?? this.notifyClassStart,
      notifyWindowOpen: notifyWindowOpen ?? this.notifyWindowOpen,
      notifySyncDone: notifySyncDone ?? this.notifySyncDone,
      notifyLowAttendance: notifyLowAttendance ?? this.notifyLowAttendance,
      lowAttendanceThreshold:
          lowAttendanceThreshold ?? this.lowAttendanceThreshold,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PreferencesNotifier extends StateNotifier<PreferencesState> {
  final PreferencesService _service;

  PreferencesNotifier(this._service) : super(const PreferencesState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    final target = await _service.getAttendanceTarget();
    final classStart = await _service.getNotifyClassStart();
    final windowOpen = await _service.getNotifyWindowOpen();
    final syncDone = await _service.getNotifySyncDone();
    final lowAttendance = await _service.getNotifyLowAttendance();
    final threshold = await _service.getLowAttendanceThreshold();
    state = PreferencesState(
      attendanceTarget: target,
      notifyClassStart: classStart,
      notifyWindowOpen: windowOpen,
      notifySyncDone: syncDone,
      notifyLowAttendance: lowAttendance,
      lowAttendanceThreshold: threshold,
      isLoading: false,
    );
  }

  Future<void> setAttendanceTarget(double value) async {
    await _service.setAttendanceTarget(value);
    state = state.copyWith(attendanceTarget: value);
  }

  Future<void> setNotifyClassStart(bool value) async {
    await _service.setNotifyClassStart(value);
    state = state.copyWith(notifyClassStart: value);
  }

  Future<void> setNotifyWindowOpen(bool value) async {
    await _service.setNotifyWindowOpen(value);
    state = state.copyWith(notifyWindowOpen: value);
  }

  Future<void> setNotifySyncDone(bool value) async {
    await _service.setNotifySyncDone(value);
    state = state.copyWith(notifySyncDone: value);
  }

  Future<void> setNotifyLowAttendance(bool value) async {
    await _service.setNotifyLowAttendance(value);
    state = state.copyWith(notifyLowAttendance: value);
  }

  Future<void> setLowAttendanceThreshold(double value) async {
    await _service.setLowAttendanceThreshold(value);
    state = state.copyWith(lowAttendanceThreshold: value);
  }
}

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, PreferencesState>((ref) {
  return PreferencesNotifier(ref.read(preferencesServiceProvider));
});
