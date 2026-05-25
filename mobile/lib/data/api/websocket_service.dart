
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:smart_attendance_app/core/constants.dart';
import 'package:smart_attendance_app/data/local/secure_storage.dart';

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(
    secureStorage: ref.read(secureStorageProvider),
  );
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
      debugPrint('WebSocket: Already connected or connecting');
      return;
    }

    _status = WebSocketStatus.connecting;
    final token = await _secureStorage.getToken();
    
    if (token == null) {
      debugPrint('WebSocket: No JWT token found, cannot connect');
      _status = WebSocketStatus.error;
      return;
    }

    try {
      
      final wsUrl = kApiBaseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
      final uri = Uri.parse('$wsUrl/ws/connect?token=$token');
      
      debugPrint('WebSocket: Connecting to $uri');
      _channel = WebSocketChannel.connect(uri);
      
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _status = WebSocketStatus.connected;
      _reconnectAttempts = 0;
      _startPingTimer();
      debugPrint('✅ WebSocket: Connected successfully');
    } catch (e) {
      debugPrint('❌ WebSocket: Connection failed: $e');
      _status = WebSocketStatus.error;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      debugPrint('📨 WebSocket message received: ${data['type']}');
      _messageController.add(data);
    } catch (e) {
      debugPrint('WebSocket: Failed to parse message: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('❌ WebSocket error: $error');
    _status = WebSocketStatus.error;
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('WebSocket: Connection closed');
    _status = WebSocketStatus.disconnected;
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WebSocket: Max reconnect attempts reached, giving up');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    
    final delay = _reconnectDelay * _reconnectAttempts;
    debugPrint('WebSocket: Scheduling reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    
    _reconnectTimer = Timer(delay, () {
      debugPrint('WebSocket: Attempting reconnect...');
      connect();
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (_status == WebSocketStatus.connected) {
        try {
          _channel?.sink.add(jsonEncode({'type': 'ping'}));
          debugPrint('WebSocket: Ping sent');
        } catch (e) {
          debugPrint('WebSocket: Ping failed: $e');
        }
      }
    });
  }

  void disconnect() {
    debugPrint('WebSocket: Disconnecting...');
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
