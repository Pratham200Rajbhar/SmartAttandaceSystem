import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_attendance_app/core/constants.dart';
import 'package:smart_attendance_app/data/local/location_service.dart';
import 'package:smart_attendance_app/features/attendance/providers/location_provider.dart';
import 'package:smart_attendance_app/data/local/hive_service.dart';
import 'package:smart_attendance_app/data/repositories/config_repository.dart';

enum GeofenceStatus {
  idle,
  scanning,
  success,
  failed,
}

class GeofenceVerificationState {
  final GeofenceStatus status;
  final String? errorMessage;
  final double? distanceMeters;
  final double? radiusMeters;
  final double? accuracy;
  final Position? position;

  const GeofenceVerificationState({
    this.status = GeofenceStatus.idle,
    this.errorMessage,
    this.distanceMeters,
    this.radiusMeters,
    this.accuracy,
    this.position,
  });

  GeofenceVerificationState copyWith({
    GeofenceStatus? status,
    String? errorMessage,
    double? distanceMeters,
    double? radiusMeters,
    double? accuracy,
    Position? position,
    bool clearError = false,
  }) {
    return GeofenceVerificationState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      distanceMeters: distanceMeters ?? this.distanceMeters,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      accuracy: accuracy ?? this.accuracy,
      position: position ?? this.position,
    );
  }
}

class GeofenceVerificationNotifier extends AutoDisposeNotifier<GeofenceVerificationState> {
  @override
  GeofenceVerificationState build() {
    return const GeofenceVerificationState();
  }

  Future<void> verifyLocation({
    required double classLat,
    required double classLng,
    required double radius,
  }) async {
    state = state.copyWith(status: GeofenceStatus.scanning, clearError: true);
    
    try {
      try {
        await ref.read(configRepositoryProvider).fetchAndCacheConfig();
      } catch (_) {}
      final config = ref.read(hiveServiceProvider).getSystemConfig();
      if (!config.isGpsVerificationEnabled) {
        // Mock success when GPS is disabled
        state = state.copyWith(
          status: GeofenceStatus.success,
          position: Position(
            longitude: classLng,
            latitude: classLat,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          ),
          distanceMeters: 0.0,
          radiusMeters: radius,
          accuracy: 0.0,
        );
        return;
      }

      final locationService = ref.read(locationServiceProvider);
      final pos = await locationService.getHighlyAccuratePosition();
      
      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        classLat,
        classLng,
      );

      final isInside = distance <= (radius + kGeofenceGraceMeters);

      if (isInside) {
        state = state.copyWith(
          status: GeofenceStatus.success,
          position: pos,
          distanceMeters: distance,
          radiusMeters: radius,
          accuracy: pos.accuracy,
        );
      } else {
        state = state.copyWith(
          status: GeofenceStatus.failed,
          errorMessage: 'You are outside the classroom boundary.',
          position: pos,
          distanceMeters: distance,
          radiusMeters: radius,
          accuracy: pos.accuracy,
        );
      }
    } on LocationException catch (e) {
      state = state.copyWith(
        status: GeofenceStatus.failed,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: GeofenceStatus.failed,
        errorMessage: 'Failed to acquire location: $e',
      );
    }
  }

  void reset() {
    state = const GeofenceVerificationState();
  }
}

final geofenceVerificationProvider = NotifierProvider.autoDispose<GeofenceVerificationNotifier, GeofenceVerificationState>(
  () => GeofenceVerificationNotifier(),
);
