
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_attendance_app/data/local/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final currentLocationProvider = FutureProvider.autoDispose<Position>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return locationService.getHighlyAccuratePosition();
});
