// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SleepRecordAdapter extends TypeAdapter<SleepRecord> {
  @override
  final int typeId = 0;

  @override
  SleepRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SleepRecord(
      bedTime: fields[0] as DateTime,
      wakeTime: fields[1] as DateTime,
      hoursSlept: fields[2] as double,
      quality: fields[3] as int,
      notes: fields[4] as String?,
      hadNightmares: fields[5] as bool,
      hadDreams: fields[6] as bool,
      wakeUps: fields[7] as int,
      autoDetected: fields[8] as bool,
      recordedAt: fields[9] as DateTime,
      accelerometerData: (fields[10] as List?)?.cast<double>(),
      avgSoundLevel: fields[11] as double?,
      usedSounds: fields[12] as bool,
      soundUsed: fields[13] as String?,
      dndActive: fields[14] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SleepRecord obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.bedTime)
      ..writeByte(1)
      ..write(obj.wakeTime)
      ..writeByte(2)
      ..write(obj.hoursSlept)
      ..writeByte(3)
      ..write(obj.quality)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.hadNightmares)
      ..writeByte(6)
      ..write(obj.hadDreams)
      ..writeByte(7)
      ..write(obj.wakeUps)
      ..writeByte(8)
      ..write(obj.autoDetected)
      ..writeByte(9)
      ..write(obj.recordedAt)
      ..writeByte(10)
      ..write(obj.accelerometerData)
      ..writeByte(11)
      ..write(obj.avgSoundLevel)
      ..writeByte(12)
      ..write(obj.usedSounds)
      ..writeByte(13)
      ..write(obj.soundUsed)
      ..writeByte(14)
      ..write(obj.dndActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
