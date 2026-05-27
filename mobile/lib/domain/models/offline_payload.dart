
import 'package:hive/hive.dart';

part 'offline_payload.g.dart';

@HiveType(typeId: 0)
class OfflineAttendancePayload extends HiveObject {
  @HiveField(0)
  final String sessionId;

  @HiveField(1)
  final double latitude;

  @HiveField(2)
  final double longitude;

  @HiveField(3)
  final String imagePath;

  @HiveField(4)
  final DateTime capturedAt;

  @HiveField(5)
  final String? className;

  @HiveField(6)
  final double? accuracy;

  OfflineAttendancePayload({
    required this.sessionId,
    required this.latitude,
    required this.longitude,
    required this.imagePath,
    required this.capturedAt,
    this.className,
    this.accuracy,
  });
}
