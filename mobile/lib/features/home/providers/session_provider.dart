
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/core/constants.dart';
import 'package:smart_attendance_app/data/api/dio_client.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/domain/enums/auth_state.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/features/auth/providers/auth_provider.dart';
import 'package:smart_attendance_app/utils/logger.dart';

class ClassSession {
  final String classId;
  final String className;
  final String subject;
  final String teacherName;
  final String? sessionId;
  final bool isActive;
  final DateTime? sessionEndTime;
  final double? latitude;
  final double? longitude;
  final double? radiusMeters;

  const ClassSession({
    required this.classId,
    required this.className,
    required this.subject,
    required this.teacherName,
    this.sessionId,
    this.isActive = false,
    this.sessionEndTime,
    this.latitude,
    this.longitude,
    this.radiusMeters,
  });
}

class SessionState {
  final List<ClassSession> sessions;
  final bool isLoading;
  final String? errorMessage;
  
  final Set<String> markedSessionIds;

  const SessionState({
    this.sessions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.markedSessionIds = const {},
  });
}

class SessionNotifier extends StateNotifier<SessionState> {
  final StudentApi _api;
  Timer? _pollTimer;
  Duration _currentInterval = kSessionPollMinInterval;

  SessionNotifier(this._api) : super(const SessionState());

  void startPolling() {
    fetchSessions();
    _schedulePoll();
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(_currentInterval, () {
      fetchSessions();
      _schedulePoll();
    });
  }

  void _adjustPollInterval(List<ClassSession> sessions) {
    final hasActive = sessions.any((s) => s.isActive);
    if (hasActive) {
      _currentInterval = kSessionPollMinInterval;
    } else {
      _currentInterval = Duration(
        seconds: (_currentInterval.inSeconds * 2)
            .clamp(kSessionPollMinInterval.inSeconds, kSessionPollMaxInterval.inSeconds),
      );
    }
  }

  List<ClassSession> _mapClasses(List<StudentClass> classes) =>
      classes.map((c) => ClassSession(
            classId: c.classId,
            className: c.className,
            subject: c.subject,
            teacherName: c.teacherName,
            sessionId: c.activeSessionId,
            isActive: c.activeSessionId != null,
            sessionEndTime: c.sessionEndTime,
            latitude: c.latitude,
            longitude: c.longitude,
            radiusMeters: c.radiusMeters,
          )).toList();

  Future<void> fetchSessions() async {
    state = SessionState(
      sessions: state.sessions,
      isLoading: true,
      markedSessionIds: state.markedSessionIds,
    );
    try {
      final classSessions = _mapClasses(await _api.getMyClasses());
      _adjustPollInterval(classSessions);
      state = SessionState(
        sessions: classSessions,
        markedSessionIds: state.markedSessionIds,
      );
    } on DioException catch (e) {
      AppLogger.error('Fetch sessions failed: $e');
      state = SessionState(
        sessions: state.sessions,
        errorMessage: mapDioError(e).message,
        markedSessionIds: state.markedSessionIds,
      );
    } catch (e) {
      AppLogger.error('Fetch sessions error: $e');
      state = SessionState(
        sessions: state.sessions,
        errorMessage: 'Failed to load sessions',
        markedSessionIds: state.markedSessionIds,
      );
    }
  }

  void markSessionSubmitted(String sessionId) {
    state = SessionState(
      sessions: state.sessions,
      markedSessionIds: {...state.markedSessionIds, sessionId},
    );
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  final notifier = SessionNotifier(ref.read(studentApiProvider));
  
  ref.listen(authProvider, (previous, next) {
    if (next.status != AuthStatus.authenticated) {
      notifier.stopPolling();
    }
  });

  return notifier;
});
