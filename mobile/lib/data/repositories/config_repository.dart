import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/data/api/dio_client.dart';
import 'package:smart_attendance_app/data/local/hive_service.dart';
import 'package:smart_attendance_app/domain/models/system_configuration.dart';

final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  return ConfigRepository(
    ref.read(dioProvider),
    ref.read(hiveServiceProvider),
  );
});

class ConfigRepository {
  final Dio _dio;
  final HiveService _hiveService;

  ConfigRepository(this._dio, this._hiveService);

  Future<void> fetchAndCacheConfig() async {
    try {
      final response = await _dio.get('/auth/config');
      if (response.statusCode == 200) {
        final config = SystemConfiguration.fromJson(response.data as Map<String, dynamic>);
        await _hiveService.cacheSystemConfig(config);
      }
    } catch (e) {
      // If network fails, we just rely on cached/default values.
    }
  }
}
