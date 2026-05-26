import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/data/local/hive_service.dart';

class PendingCountNotifier extends StateNotifier<int> {
  final HiveService _hive;
  PendingCountNotifier(this._hive) : super(_hive.pendingCount);

  void refresh() {
    state = _hive.pendingCount;
  }
}

final pendingCountProvider = StateNotifierProvider<PendingCountNotifier, int>((ref) {
  return PendingCountNotifier(ref.read(hiveServiceProvider));
});
