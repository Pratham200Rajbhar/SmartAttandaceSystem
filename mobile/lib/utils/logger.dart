import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:smart_attendance_app/core/constants.dart';

/// A centralized logging utility that sends logs to the backend.
class AppLogger {
  static Future<void> _sendLog(String level, String message, {Map<String, dynamic>? context}) async {
    try {
      final payload = {
        'source': 'mobile',
        'level': level,
        'message': message,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        if (context != null) 'context': context,
      };

      await http.post(
        Uri.parse('$kApiBaseUrl/logs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      // Print locally if we fail to send
      debugPrint('[LoggerError] Failed to send log: $e');
    }
  }

  /// Logs informational messages.
  static void info(String message, {Map<String, dynamic>? context}) {
    debugPrint('[INFO] $message');
    _sendLog('INFO', message, context: context);
  }

  /// Logs warning messages.
  static void warn(String message, {Map<String, dynamic>? context}) {
    debugPrint('[WARN] $message');
    _sendLog('WARN', message, context: context);
  }

  /// Logs error messages.
  static void error(String message, {Map<String, dynamic>? context}) {
    debugPrint('[ERROR] $message');
    _sendLog('ERROR', message, context: context);
  }

  /// Logs debug-only messages.
  static void debug(String message, {Map<String, dynamic>? context}) {
    debugPrint('[DEBUG] $message');
    _sendLog('DEBUG', message, context: context);
  }
}
