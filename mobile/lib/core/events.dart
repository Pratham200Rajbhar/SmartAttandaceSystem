import 'dart:async';

class AppEvents {
  static final StreamController<String> _authErrorController = StreamController<String>.broadcast();

  static Stream<String> get authErrorStream => _authErrorController.stream;

  static void broadcastAuthError(String reason) {
    _authErrorController.add(reason);
  }
}
