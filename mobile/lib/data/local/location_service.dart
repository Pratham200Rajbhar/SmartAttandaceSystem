
import 'dart:async';
import 'package:geolocator/geolocator.dart';

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
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (pos.isMocked) {
        throw const LocationException(
          'Mocked location detected. Attendance blocked.',
        );
      }

      return pos;
    } on TimeoutException {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos == null) {
        throw const LocationException(
          'GPS timed out and no last known position available.',
        );
      }
      return lastPos;
    }
  }

  bool isWithinGeofence(
    Position student,
    double classLat,
    double classLng, {
    double radiusMeters = 50.0,
  }) {
    final distance = Geolocator.distanceBetween(
      student.latitude,
      student.longitude,
      classLat,
      classLng,
    );
    return distance <= radiusMeters;
  }
}
