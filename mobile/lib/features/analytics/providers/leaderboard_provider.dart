import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/domain/models/leaderboard.dart';
import 'package:smart_attendance_app/utils/logger.dart';

class LeaderboardState {
  final LeaderboardResponse? data;
  final bool isLoading;
  final String? errorMessage;

  const LeaderboardState({
    this.data,
    this.isLoading = false,
    this.errorMessage,
  });

  LeaderboardState copyWith({
    LeaderboardResponse? data,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LeaderboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final StudentApi _api;

  LeaderboardNotifier(this._api) : super(const LeaderboardState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _api.getLeaderboard();
      state = LeaderboardState(data: res);
    } catch (e) {
      AppLogger.error('Fetch leaderboard failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load leaderboard data.',
      );
    }
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref.read(studentApiProvider));
});
