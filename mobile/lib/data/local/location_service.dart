
import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:smart_attendance_app/core/constants.dart';

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  Future<void> ensurePermissionsGranted() async {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      throw const LocationException('Location services are disabled on your device.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission permanently denied. Open Settings to enable.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException('Location permission denied.');
    }
  }

  Future<Position> getHighlyAccuratePosition() async {
    await ensurePermissionsGranted();

    try {
      final accuracyStatus = await Geolocator.getLocationAccuracy();
      if (accuracyStatus == LocationAccuracyStatus.reduced) {
        throw const LocationException(
          'Precise location is disabled. Please enable "Precise Location" in your system settings for this app.',
        );
      }
    } catch (_) {
      // Ignore if not supported on this platform/version
    }

    final completer = Completer<Position>();
    StreamSubscription<Position>? subscription;
    Timer? timeoutTimer;
    Position? bestPosition;

    void cleanup() {
      timeoutTimer?.cancel();
      subscription?.cancel();
    }

    // Set a timeout based on app constants
    final timeoutDuration = Duration(seconds: kGpsTimeoutSeconds);

    timeoutTimer = Timer(timeoutDuration, () {
      cleanup();
      if (!completer.isCompleted) {
        if (bestPosition != null) {
          if (bestPosition!.accuracy > kMinGpsAccuracyMeters) {
            completer.completeError(
              const LocationException(
                'GPS signal too weak. Please move near a window.',
              ),
            );
          } else {
            completer.complete(bestPosition!);
          }
        } else {
          completer.completeError(
            const LocationException(
              'GPS request timed out. Please ensure your device location is turned on and has a clear view of the sky.',
            ),
          );
        }
      }
    });

    try {
      subscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).listen(
        (Position pos) {
          if (pos.isMocked) {
            cleanup();
            if (!completer.isCompleted) {
              completer.completeError(
                const LocationException('Mocked location detected. Attendance blocked.'),
              );
            }
            return;
          }

          // Track the best position received so far
          if (bestPosition == null || pos.accuracy < bestPosition!.accuracy) {
            bestPosition = pos;
          }

          // If we reach the required accuracy threshold, resolve immediately!
          if (pos.accuracy <= kMinGpsAccuracyMeters) {
            cleanup();
            if (!completer.isCompleted) {
              completer.complete(pos);
            }
          }
        },
        onError: (e) {
          cleanup();
          if (!completer.isCompleted) {
            completer.completeError(LocationException('Failed to acquire location: $e'));
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      cleanup();
      if (!completer.isCompleted) {
        completer.completeError(LocationException('Failed to start location stream: $e'));
      }
    }

    final finalPos = await completer.future;
    if (finalPos.isMocked) {
      throw const LocationException('Mocked location detected. Attendance blocked.');
    }
    if (finalPos.accuracy > 60.0) {
      throw const LocationException('GPS signal too weak. Please move near a window.');
    }
    return finalPos;
  }

  Future<Position> getAveragedPosition({int samples = kGpsAveragingSamples}) async {
    List<Position> positions = [];

    for (int i = 0; i < samples; i++) {
      try {
        final pos = await getHighlyAccuratePosition();
        positions.add(pos);
        if (i < samples - 1) {
          await Future.delayed(const Duration(seconds: 3));
        }
      } on LocationException {
        if (i < samples - 1) {
          await Future.delayed(const Duration(seconds: 3));
        }
      }
    }

    if (positions.isEmpty) {
      throw const LocationException(
        'Could not acquire enough GPS samples for position averaging.',
      );
    }

    final meanLat = positions.map((p) => p.latitude).reduce((a, b) => a + b) / positions.length;
    final meanLng = positions.map((p) => p.longitude).reduce((a, b) => a + b) / positions.length;

    final varianceLat = positions.map((p) => pow(p.latitude - meanLat, 2)).reduce((a, b) => a + b) / positions.length;
    final varianceLng = positions.map((p) => pow(p.longitude - meanLng, 2)).reduce((a, b) => a + b) / positions.length;
    final stdDev = sqrt(varianceLat + varianceLng) * 111320;

    if (stdDev > 20) {
      throw LocationException(
        'GPS readings unstable (stdDev: ${stdDev.toStringAsFixed(0)}m). Hold steady and retry.',
      );
    }

    final best = positions.reduce((a, b) => a.accuracy <= b.accuracy ? a : b);

    return Position(
      longitude: meanLng,
      latitude: meanLat,
      accuracy: best.accuracy,
      altitude: best.altitude,
      heading: best.heading,
      speed: best.speed,
      speedAccuracy: best.speedAccuracy,
      timestamp: best.timestamp,
      altitudeAccuracy: best.altitudeAccuracy,
      headingAccuracy: best.headingAccuracy,
    );
  }

  bool isWithinGeofence(
    Position student,
    double classLat,
    double classLng, {
    double radiusMeters = 100.0,
  }) {
    final distance = Geolocator.distanceBetween(
      student.latitude,
      student.longitude,
      classLat,
      classLng,
    );
    return distance <= radiusMeters + kGeofenceGraceMeters;
  }

  String describeDistance(
    Position student,
    double classLat,
    double classLng,
  ) {
    final distance = Geolocator.distanceBetween(
      student.latitude,
      student.longitude,
      classLat,
      classLng,
    );
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    }
    return '${(distance / 1000).toStringAsFixed(1)}km';
  }
}
