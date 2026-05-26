
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

class PreferencesService {
  static const _keyAttendanceTarget = 'pref_attendance_target';
  static const _keyNotifyClassStart = 'pref_notify_class_start';
  static const _keyNotifyWindowOpen = 'pref_notify_window_open';
  static const _keyNotifySyncDone = 'pref_notify_sync_done';
  static const _keyNotifyLowAttendance = 'pref_notify_low_attendance';
  static const _keyLowAttendanceThreshold = 'pref_low_attendance_threshold';
  static const _keyFirstCameraUse = 'pref_first_camera_use';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<double> getAttendanceTarget() async {
    final prefs = await _instance;
    return prefs.getDouble(_keyAttendanceTarget) ?? 75.0;
  }

  Future<void> setAttendanceTarget(double value) async {
    final prefs = await _instance;
    await prefs.setDouble(_keyAttendanceTarget, value);
  }

  Future<bool> getNotifyClassStart() async {
    final prefs = await _instance;
    return prefs.getBool(_keyNotifyClassStart) ?? true;
  }

  Future<void> setNotifyClassStart(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_keyNotifyClassStart, value);
  }

  Future<bool> getNotifyWindowOpen() async {
    final prefs = await _instance;
    return prefs.getBool(_keyNotifyWindowOpen) ?? true;
  }

  Future<void> setNotifyWindowOpen(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_keyNotifyWindowOpen, value);
  }

  Future<bool> getNotifySyncDone() async {
    final prefs = await _instance;
    return prefs.getBool(_keyNotifySyncDone) ?? true;
  }

  Future<void> setNotifySyncDone(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_keyNotifySyncDone, value);
  }

  Future<bool> getNotifyLowAttendance() async {
    final prefs = await _instance;
    return prefs.getBool(_keyNotifyLowAttendance) ?? true;
  }

  Future<void> setNotifyLowAttendance(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_keyNotifyLowAttendance, value);
  }

  Future<double> getLowAttendanceThreshold() async {
    final prefs = await _instance;
    return prefs.getDouble(_keyLowAttendanceThreshold) ?? 75.0;
  }

  Future<void> setLowAttendanceThreshold(double value) async {
    final prefs = await _instance;
    await prefs.setDouble(_keyLowAttendanceThreshold, value);
  }

  Future<bool> isFirstCameraUse() async {
    final prefs = await _instance;
    return prefs.getBool(_keyFirstCameraUse) ?? true;
  }

  Future<void> markCameraUsed() async {
    final prefs = await _instance;
    await prefs.setBool(_keyFirstCameraUse, false);
  }
}
