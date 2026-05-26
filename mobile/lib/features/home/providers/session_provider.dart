
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/core/constants.dart';
import 'package:smart_attendance_app/data/api/dio_client.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/domain/enums/auth_state.dart';
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
                latitude: c.latitude,
                longitude: c.longitude,
              ))
          .toList();

      final hasActive = classSessions.any((s) => s.isActive);

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
      AppLogger.error('SessionNotifier.fetchSessions DioException: $e', context: {'error': e.toString(), 'stackTrace': stackTrace.toString()});
      final mapped = mapDioError(e);
      state = SessionState(
        sessions: state.sessions,
        errorMessage: mapped.message,
        markedSessionIds: state.markedSessionIds,
      );
    } catch (e, stackTrace) {
      AppLogger.error('SessionNotifier.fetchSessions unexpected error: $e', context: {'error': e.toString(), 'stackTrace': stackTrace.toString()});
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
