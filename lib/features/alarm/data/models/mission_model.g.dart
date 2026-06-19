// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MissionModelAdapter extends TypeAdapter<MissionModel> {
  @override
  final int typeId = 1;

  @override
  MissionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MissionModel(
      type: fields[0] as HiveMissionType,
      difficulty: fields[1] as int,
      targetCount: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MissionModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.difficulty)
      ..writeByte(2)
      ..write(obj.targetCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveMissionTypeAdapter extends TypeAdapter<HiveMissionType> {
  @override
  final int typeId = 2;

  @override
  HiveMissionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HiveMissionType.none;
      case 1:
        return HiveMissionType.math;
      case 2:
        return HiveMissionType.shake;
      case 3:
        return HiveMissionType.captcha;
      case 4:
        return HiveMissionType.memory;
      default:
        return HiveMissionType.none;
    }
  }

  @override
  void write(BinaryWriter writer, HiveMissionType obj) {
    switch (obj) {
      case HiveMissionType.none:
        writer.writeByte(0);
        break;
      case HiveMissionType.math:
        writer.writeByte(1);
        break;
      case HiveMissionType.shake:
        writer.writeByte(2);
        break;
      case HiveMissionType.captcha:
        writer.writeByte(3);
        break;
      case HiveMissionType.memory:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveMissionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
