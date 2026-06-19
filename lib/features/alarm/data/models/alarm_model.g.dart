// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmModelAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 0;

  @override
  AlarmModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmModel(
      id: fields[0] as int,
      dateTime: fields[1] as DateTime,
      label: fields[2] as String,
      repeatDays: (fields[3] as List).cast<int>(),
      isEnabled: fields[4] as bool,
      snoozeDurationMinutes: fields[5] as int,
      maxSnoozeCount: fields[6] as int,
      currentSnoozeCount: fields[7] as int,
      audioPath: fields[8] as String,
      volume: fields[9] as double,
      vibrate: fields[10] as bool,
      fadeDurationSeconds: fields[11] as int,
      mission: fields[12] as MissionModel,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dateTime)
      ..writeByte(2)
      ..write(obj.label)
      ..writeByte(3)
      ..write(obj.repeatDays)
      ..writeByte(4)
      ..write(obj.isEnabled)
      ..writeByte(5)
      ..write(obj.snoozeDurationMinutes)
      ..writeByte(6)
      ..write(obj.maxSnoozeCount)
      ..writeByte(7)
      ..write(obj.currentSnoozeCount)
      ..writeByte(8)
      ..write(obj.audioPath)
      ..writeByte(9)
      ..write(obj.volume)
      ..writeByte(10)
      ..write(obj.vibrate)
      ..writeByte(11)
      ..write(obj.fadeDurationSeconds)
      ..writeByte(12)
      ..write(obj.mission);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
