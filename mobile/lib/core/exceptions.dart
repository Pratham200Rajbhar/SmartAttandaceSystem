// Typed exception hierarchy for structured error handling across the app.
library;

// Base exception class that all app exceptions extend.
sealed class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Network-layer failures (timeouts, DNS, connection refused).
class NetworkException extends AppException {
  const NetworkException(super.message, {super.statusCode});
}

/// Authentication failures (401, expired/revoked tokens).
class AuthException extends AppException {
  const AuthException(super.message, {super.statusCode});
}

/// Input validation failures (400-class errors from backend).
class ValidationException extends AppException {
  const ValidationException(super.message, {super.statusCode});
}

/// Server-side errors (500-class responses).
class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});
}

/// Device binding conflict (UUID mismatch).
class DeviceBindingException extends AppException {
  const DeviceBindingException(super.message, {super.statusCode});
}

/// GPS/location service failures.
class LocationException extends AppException {
  const LocationException(super.message, {super.statusCode});
}
