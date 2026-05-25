
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/domain/models/leave_request.dart';

class LeaveState {
  final List<LeaveRequest> leaves;
  final bool isLoading;
  final String? errorMessage;
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const LeaveState({
    this.leaves = const [],
    this.isLoading = false,
    this.errorMessage,
    this.total = 0,
    this.pending = 0,
    this.approved = 0,
    this.rejected = 0,
  });

  LeaveState copyWith({
    List<LeaveRequest>? leaves,
    bool? isLoading,
    String? errorMessage,
    int? total,
    int? pending,
    int? approved,
    int? rejected,
  }) {
    return LeaveState(
      leaves: leaves ?? this.leaves,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      total: total ?? this.total,
      pending: pending ?? this.pending,
      approved: approved ?? this.approved,
      rejected: rejected ?? this.rejected,
    );
  }
}

class LeaveNotifier extends StateNotifier<LeaveState> {
  final StudentApi _api;

  LeaveNotifier(this._api) : super(const LeaveState());

  Future<void> fetchLeaves() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _api.getMyLeaves();
      final response = LeaveRequestListResponse.fromJson(data);
      
      state = LeaveState(
        leaves: response.leaves,
        isLoading: false,
        total: response.total,
        pending: response.pending,
        approved: response.approved,
        rejected: response.rejected,
      );
    } catch (e) {
      debugPrint('Failed to fetch leaves: $e');
      state = LeaveState(
        isLoading: false,
        errorMessage: 'Failed to load leave requests: $e',
      );
    }
  }

  Future<bool> createLeave({
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? documentPath,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _api.createLeaveRequest(
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        documentPath: documentPath,
      );
      
      await fetchLeaves();
      return true;
    } catch (e) {
      debugPrint('Failed to create leave: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create leave request: $e',
      );
      return false;
    }
  }
}

final leaveProvider = StateNotifierProvider<LeaveNotifier, LeaveState>((ref) {
  return LeaveNotifier(ref.read(studentApiProvider));
});
