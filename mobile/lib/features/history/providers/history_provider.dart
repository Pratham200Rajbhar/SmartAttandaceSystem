
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/data/api/websocket_service.dart';
import 'package:smart_attendance_app/data/repositories/attendance_repository.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/utils/logger.dart';

class HistoryState {
  final AttendanceHistoryResponse? data;
  final bool isLoading;
  final String? errorMessage;

  const HistoryState({this.data, this.isLoading = false, this.errorMessage});

  Map<DateTime, List<AttendanceHistoryItem>> get groupedByDate {
    final history = data?.history ?? [];
    final map = <DateTime, List<AttendanceHistoryItem>>{};
    for (final item in history) {
      final dateKey =
          DateTime(item.markedAt.year, item.markedAt.month, item.markedAt.day);
      map.putIfAbsent(dateKey, () => []).add(item);
    }
    return map;
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final AttendanceRepository _repo;

  HistoryNotifier(this._repo) : super(const HistoryState());

  Future<void> fetch() async {
    state = HistoryState(data: state.data, isLoading: true);
    try {
      state = HistoryState(data: await _repo.getHistory());
    } catch (e) {
      AppLogger.error('Fetch history failed: $e');
      state = HistoryState(
        data: state.data,
        errorMessage: e is Exception ? e.toString() : 'Something went wrong. Please try again.',
      );
    }
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final notifier = HistoryNotifier(ref.read(attendanceRepositoryProvider));
  final wsService = ref.read(websocketServiceProvider);
  
  final subscription = wsService.messageStream.listen((message) {
    if (message['type'] == 'attendance_updated') {
      notifier.fetch();
    }
  });

  ref.onDispose(() {
    subscription.cancel();
  });

  return notifier;
});
