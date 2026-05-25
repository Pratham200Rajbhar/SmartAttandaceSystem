// Session provider — manages active class sessions for the home dashboard.
// Implements exponential backoff polling: starts at 15s, doubles to 60s max
// when no active sessions are found, resets to 15s when a session appears.
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/core/constants.dart';
import 'package:smart_attendance_app/data/api/dio_client.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';

/// A class session card model for the home dashboard.
class ClassSession {
  final String classId;
  final String className;
  final String subject;
  final String teacherName;
  final String? sessionId;
  final bool isActive;
  final DateTime? sessionEndTime;

  const ClassSession({
    required this.classId,
    required this.className,
    required this.subject,
    required this.teacherName,
    this.sessionId,
    this.isActive = false,
    this.sessionEndTime,
  });
}

class SessionState {
  final List<ClassSession> sessions;
  final bool isLoading;
  final String? errorMessage;
  /// Set of session IDs where the student already has a record.
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

  /// Starts periodic polling for session data with exponential backoff.
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

  /// Fetches enrolled classes and their active session status.
  Future<void> fetchSessions() async {
    state = SessionState(
      sessions: state.sessions,
      isLoading: true,
      markedSessionIds: state.markedSessionIds,
    );
    try {
      final classes = await _api.getMyClasses();

      final classSessions = classes
          .map((c) => ClassSession(
                classId: c.classId,
                className: c.className,
                subject: c.subject,
                teacherName: c.teacherName,
                sessionId: c.activeSessionId,
                isActive: c.activeSessionId != null,
                sessionEndTime: c.sessionEndTime,
              ))
          .toList();

      final hasActive = classSessions.any((s) => s.isActive);

      // Exponential backoff: reset on active session, grow when idle
      if (hasActive) {
        _currentInterval = kSessionPollMinInterval;
      } else {
        _currentInterval = Duration(
          seconds: (_currentInterval.inSeconds * 2)
              .clamp(kSessionPollMinInterval.inSeconds, kSessionPollMaxInterval.inSeconds),
        );
      }

      state = SessionState(
        sessions: classSessions,
        markedSessionIds: state.markedSessionIds,
      );
    } on DioException catch (e, stackTrace) {
      debugPrint('SessionNotifier.fetchSessions DioException: $e\n$stackTrace');
      final mapped = mapDioError(e);
      state = SessionState(
        sessions: state.sessions,
        errorMessage: mapped.message,
        markedSessionIds: state.markedSessionIds,
      );
    } catch (e, stackTrace) {
      debugPrint('SessionNotifier.fetchSessions unexpected error: $e\n$stackTrace');
      state = SessionState(
        sessions: state.sessions,
        errorMessage: 'Failed to load sessions',
        markedSessionIds: state.markedSessionIds,
      );
    }
  }

  /// Marks a session as already submitted by the student.
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
  return SessionNotifier(ref.read(studentApiProvider));
});
