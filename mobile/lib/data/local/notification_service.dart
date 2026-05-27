
library;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_attendance_app/core/constants.dart';

class LocalNotification {
  final String title;
  final String body;
  final DateTime timestamp;
  final String severity; 
  final String source; 
  final bool isRead;

  LocalNotification({
    required this.title,
    required this.body,
    required this.timestamp,
    required this.severity,
    this.source = 'local',
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'severity': severity,
        'source': source,
        'is_read': isRead,
      };

  factory LocalNotification.fromMap(Map<dynamic, dynamic> map) {
    return LocalNotification(
      title: map['title'] as String,
      body: map['body'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      severity: map['severity'] as String,
      source: map['source'] as String? ?? 'local',
      isRead: map['is_read'] as bool? ?? false,
    );
  }

  LocalNotification copyWith({bool? isRead}) => LocalNotification(
        title: title,
        body: body,
        timestamp: timestamp,
        severity: severity,
        source: source,
        isRead: isRead ?? this.isRead,
      );
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  Box<Map<dynamic, dynamic>>? _box;

  bool get isInitialized => _box != null;

  Future<void> initialize() async {
    _box = await Hive.openBox<Map<dynamic, dynamic>>(kHiveBoxNotifications);
  }

  Future<void> _ensureInitialized() async {
    if (_box == null) await initialize();
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required String severity,
    String source = 'local',
  }) async {
    await _ensureInitialized();
    final notification = LocalNotification(
      title: title,
      body: body,
      timestamp: DateTime.now(),
      severity: severity,
      source: source,
    );
    await _box?.add(notification.toMap());
  }

  List<LocalNotification> getNotifications() {
    if (_box == null) return [];
    final items =
        _box!.values.map((m) => LocalNotification.fromMap(m)).toList();
    
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> clearAll() async {
    await _box?.clear();
  }

  Future<void> replaceAll(List<LocalNotification> notifications) async {
    await _box?.clear();
    for (final n in notifications) {
      await _box?.add(n.toMap());
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<LocalNotification>>(
        (ref) {
  return NotificationsNotifier(ref.read(notificationServiceProvider));
});

final notificationsLoadingProvider = Provider<bool>((ref) {
  return ref.read(notificationsProvider.notifier).isLoading;
});

class NotificationsNotifier extends StateNotifier<List<LocalNotification>> {
  final NotificationService _service;
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  NotificationsNotifier(this._service) : super([]) {
    load();
  }

  Future<void> load() async {
    _isLoading = true;
    if (!_service.isInitialized) {
      await _service.initialize();
    }
    state = _service.getNotifications();
    _isLoading = false;
  }

  Future<void> clear() async {
    await _service.clearAll();
    state = [];
  }

  Future<void> markAllRead() async {
    final updated = state.map((n) => n.copyWith(isRead: true)).toList();
    await _service.replaceAll(updated);
    state = updated;
  }
}
