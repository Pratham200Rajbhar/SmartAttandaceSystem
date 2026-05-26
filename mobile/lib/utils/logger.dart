import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:smart_attendance_app/core/constants.dart';

/// Unified logger for the Smart Attendance mobile app.
///
/// Every call:
///  1. Prints to the debug console via [debugPrint].
///  2. Ships the event to the backend [kApiBaseUrl]/logs endpoint so it lands
///     in logs/mobile.log on the server.
///
/// All log payloads automatically include the app version and platform name.
/// A single retry is attempted on network timeout to handle brief connectivity
/// gaps without blocking the UI.
class AppLogger {
  AppLogger._(); // prevent instantiation

  static String? _userId;

  /// Declare the app version inline — kept in sync with pubspec.yaml version field.
  static const String _appVersion = '1.0.0+1';

  /// Set the authenticated user's ID so it is included in subsequent logs.
  static void setUserId(String? userId) {
    _userId = userId;
  }

  // --------------------------------------------------------------------------
  // Public log methods
  // --------------------------------------------------------------------------

  /// Fine-grained diagnostic information.
  static void debug(String message, {Map<String, dynamic>? context}) {
    _emit('DEBUG', message, context: context);
  }

  /// Routine operational events — navigation, successful API calls, etc.
  static void info(String message, {Map<String, dynamic>? context}) {
    _emit('INFO', message, context: context);
  }

  /// Non-fatal issues the system can recover from.
  static void warn(String message, {Map<String, dynamic>? context}) {
    _emit('WARN', message, context: context);
  }

  /// Errors that degrade user-visible functionality.
  static void error(String message, {Map<String, dynamic>? context}) {
    _emit('ERROR', message, context: context);
  }

  /// Severe failures — unhandled exceptions, app crashes.
  static void critical(String message, {Map<String, dynamic>? context}) {
    _emit('CRITICAL', message, context: context);
  }

  // --------------------------------------------------------------------------
  // Internal helpers
  // --------------------------------------------------------------------------

  static void _emit(
    String level,
    String message, {
    Map<String, dynamic>? context,
  }) {
    final prefix = '[${level.padRight(8)}]';
    debugPrint('$prefix $message');

    // Fire-and-forget — must not block the caller
    _sendLog(level, message, context: context);
  }

  static Future<void> _sendLog(
    String level,
    String message, {
    Map<String, dynamic>? context,
    int attempt = 0,
  }) async {
    final payload = <String, dynamic>{
      'source': 'mobile',
      'level': level,
      'message': message,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'platform_version': _appVersion,
      'platform': _resolvePlatformName(),
      if (_userId != null) 'user_id': _userId,
      if (context != null) 'context': context,
    };

    try {
      await http
          .post(
            Uri.parse('$kApiBaseUrl/logs'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));
    } on SocketException catch (e) {
      // Network unavailable — silently drop, no retry needed
      debugPrint('[AppLogger] Network unavailable, log dropped: $e');
    } on TimeoutException catch (e) {
      if (attempt < 1) {
        // One retry on timeout
        debugPrint('[AppLogger] Timeout, retrying log: $e');
        await _sendLog(level, message, context: context, attempt: attempt + 1);
      } else {
        debugPrint('[AppLogger] Retry failed, log dropped: $e');
      }
    } catch (e) {
      debugPrint('[AppLogger] Failed to send log: $e');
    }
  }

  static String _resolvePlatformName() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
