import 'package:hive/hive.dart';
import '../../domain/entities/alarm_entity.dart';
import 'mission_model.dart';

part 'alarm_model.g.dart';

@HiveType(typeId: 0)
class AlarmModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final DateTime dateTime;

  @HiveField(2)
  final String label;

  @HiveField(3)
  final List<int> repeatDays;

  @HiveField(4)
  final bool isEnabled;

  @HiveField(5)
  final int snoozeDurationMinutes;

  @HiveField(6)
  final int maxSnoozeCount;

  @HiveField(7)
  final int currentSnoozeCount;

  @HiveField(8)
  final String audioPath;

  @HiveField(9)
  final double volume;

  @HiveField(10)
  final bool vibrate;

  @HiveField(11)
  final int fadeDurationSeconds;

  @HiveField(12)
  final MissionModel mission;

  AlarmModel({
    required this.id,
    required this.dateTime,
    required this.label,
    required this.repeatDays,
    required this.isEnabled,
    required this.snoozeDurationMinutes,
    required this.maxSnoozeCount,
    required this.currentSnoozeCount,
    required this.audioPath,
    required this.volume,
    required this.vibrate,
    required this.fadeDurationSeconds,
    required this.mission,
  });

  // Convert to Domain Entity
  AlarmEntity toEntity() {
    return AlarmEntity(
      id: id,
      dateTime: dateTime,
      label: label,
      repeatDays: repeatDays,
      isEnabled: isEnabled,
      snoozeDurationMinutes: snoozeDurationMinutes,
      maxSnoozeCount: maxSnoozeCount,
      currentSnoozeCount: currentSnoozeCount,
      audioPath: audioPath,
      volume: volume,
      vibrate: vibrate,
      fadeDurationSeconds: fadeDurationSeconds,
      mission: mission.toEntity(),
    );
  }

  // Convert from Domain Entity
  factory AlarmModel.fromEntity(AlarmEntity entity) {
    return AlarmModel(
      id: entity.id,
      dateTime: entity.dateTime,
      label: entity.label,
      repeatDays: entity.repeatDays,
      isEnabled: entity.isEnabled,
      snoozeDurationMinutes: entity.snoozeDurationMinutes,
      maxSnoozeCount: entity.maxSnoozeCount,
      currentSnoozeCount: entity.currentSnoozeCount,
      audioPath: entity.audioPath,
      volume: entity.volume,
      vibrate: entity.vibrate,
      fadeDurationSeconds: entity.fadeDurationSeconds,
      mission: MissionModel.fromEntity(entity.mission),
    );
  }
}
