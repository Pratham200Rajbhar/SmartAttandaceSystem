
part of 'offline_payload.dart';

class OfflineAttendancePayloadAdapter
    extends TypeAdapter<OfflineAttendancePayload> {
  @override
  final int typeId = 0;

  @override
  OfflineAttendancePayload read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineAttendancePayload(
      sessionId: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      imagePath: fields[3] as String,
      capturedAt: fields[4] as DateTime,
      className: fields[5] as String?,
      accuracy: fields[6] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineAttendancePayload obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.capturedAt)
      ..writeByte(5)
      ..write(obj.className)
      ..writeByte(6)
      ..write(obj.accuracy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineAttendancePayloadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
