import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void debug(String message, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('⚫ $message${context != null ? ' $context' : ''}');
    }
  }

  static void info(String message, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('🔵 $message${context != null ? ' $context' : ''}');
    }
  }

  static void warn(String message, {Map<String, dynamic>? context}) {
    // ignore: avoid_print
    print('🟡 $message${context != null ? ' $context' : ''}');
  }

  static void error(String message, {Map<String, dynamic>? context}) {
    // ignore: avoid_print
    print('🔴 $message${context != null ? ' $context' : ''}');
  }
}
