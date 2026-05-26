
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/core/constants.dart';
import 'package:smart_attendance_app/core/exceptions.dart';
import 'package:smart_attendance_app/core/events.dart';
import 'package:smart_attendance_app/data/local/secure_storage.dart';
import 'package:smart_attendance_app/utils/logger.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: kApiBaseUrl,
    connectTimeout: const Duration(milliseconds: kConnectTimeout),
    receiveTimeout: const Duration(milliseconds: kReceiveTimeout),
    headers: {'Accept': 'application/json'},
  ));

  final storage = ref.read(secureStorageProvider);

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onResponse: (response, handler) {
      handler.next(response);
    },
    onError: (error, handler) async {
      AppLogger.error('[HTTP] ${error.requestOptions.method} ${error.requestOptions.path}: ${error.message}');
      if (error.response?.statusCode == 401 &&
          !error.requestOptions.path.endsWith('/auth/login') &&
          !error.requestOptions.path.endsWith('/auth/logout')) {
        await storage.clearAll();
        AppEvents.broadcastAuthError('session_expired');
      }
      handler.next(error);
    },
  ));

  return dio;
});

AppException mapDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkException('Connection timed out. Please try again.');
    case DioExceptionType.connectionError:
      return const NetworkException(
          'Unable to connect to the server. Check your internet connection.');
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode ?? 0;
      final detail = _extractDetail(error.response?.data);
      if (statusCode == 401) {
        return AuthException(detail, statusCode: statusCode);
      }
      if (statusCode == 403) {
        return AuthException('Access forbidden', statusCode: statusCode);
      }
      if (statusCode >= 400 && statusCode < 500) {
        return ValidationException(detail, statusCode: statusCode);
      }
      return ServerException(detail, statusCode: statusCode);
    default:
      return NetworkException(
          error.message ?? 'An unexpected network error occurred.');
  }
}

String _extractDetail(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data['detail']?.toString() ?? 'Something went wrong';
  }
  return 'Something went wrong';
}
