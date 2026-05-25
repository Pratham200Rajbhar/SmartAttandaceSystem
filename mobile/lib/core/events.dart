import 'dart:async';

/// Global event bus for broadcasting application-wide events.
/// This helps in breaking circular dependencies between providers (e.g., DioClient -> AuthNotifier).
class AppEvents {
  static final StreamController<String> _authErrorController = StreamController<String>.broadcast();

  static Stream<String> get authErrorStream => _authErrorController.stream;

  static void broadcastAuthError(String reason) {
    _authErrorController.add(reason);
  }
}
