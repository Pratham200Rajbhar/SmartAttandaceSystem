
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:smart_attendance_app/core/constants.dart';
import 'package:smart_attendance_app/data/local/secure_storage.dart';
import 'package:smart_attendance_app/domain/enums/auth_state.dart';
import 'package:smart_attendance_app/features/auth/providers/auth_provider.dart';
import 'package:smart_attendance_app/utils/logger.dart';

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService(
    secureStorage: ref.read(secureStorageProvider),
  );

  final authState = ref.read(authProvider);
  if (authState.status == AuthStatus.authenticated) {
    service.connect();
  }

  ref.listen(authProvider, (previous, next) {
    if (next.status == AuthStatus.authenticated) {
      service.connect();
    } else if (next.status == AuthStatus.unauthenticated) {
      service.disconnect();
    }
  });

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

enum WebSocketStatus { disconnected, connecting, connected, error }

class WebSocketService {
  final SecureStorageService _secureStorage;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  WebSocketStatus _status = WebSocketStatus.disconnected;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 30);

  WebSocketService({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage;

  WebSocketStatus get status => _status;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Future<void> connect() async {
    if (_status == WebSocketStatus.connected || _status == WebSocketStatus.connecting) {
      return;
    }

    _status = WebSocketStatus.connecting;
    final token = await _secureStorage.getToken();
    
    if (token == null) {
      _status = WebSocketStatus.error;
      return;
    }

    try {
      final wsUrl = kApiBaseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
      final uri = Uri.parse('$wsUrl/ws/connect');
      
      _channel = WebSocketChannel.connect(uri);
      
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      await _channel!.ready;
      _channel!.sink.add(jsonEncode({'type': 'auth', 'token': token}));

      _status = WebSocketStatus.connected;
      _reconnectAttempts = 0;
      _startPingTimer();
    } catch (e) {
      AppLogger.error('WebSocket: Connection failed: $e');
      _status = WebSocketStatus.error;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      _messageController.add(data);
    } catch (e) {
      AppLogger.error('WebSocket: Failed to parse message: $e');
    }
  }

  void _onError(dynamic error) {
    AppLogger.error('WebSocket error: $error');
    _status = WebSocketStatus.error;
    _scheduleReconnect();
  }

  void _onDone() {
    _status = WebSocketStatus.disconnected;
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    
    final delay = _reconnectDelay * _reconnectAttempts;
    
    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (_status == WebSocketStatus.connected) {
        try {
          _channel?.sink.add(jsonEncode({'type': 'ping'}));
        } catch (_) {}
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _status = WebSocketStatus.disconnected;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
