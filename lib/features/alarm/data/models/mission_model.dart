import 'package:hive/hive.dart';
import '../../domain/entities/mission_entity.dart';

part 'mission_model.g.dart';

@HiveType(typeId: 2)
enum HiveMissionType {
  @HiveField(0)
  none,
  @HiveField(1)
  math,
  @HiveField(2)
  shake,
  @HiveField(3)
  captcha,
  @HiveField(4)
  memory,
}

@HiveType(typeId: 1)
class MissionModel extends HiveObject {
  @HiveField(0)
  final HiveMissionType type;

  @HiveField(1)
  final int difficulty;

  @HiveField(2)
  final int targetCount;

  MissionModel({
    required this.type,
    this.difficulty = 1,
    this.targetCount = 5,
  });

  // Convert to domain entity
  MissionEntity toEntity() {
    return MissionEntity(
      type: MissionType.values[type.index],
      difficulty: difficulty,
      targetCount: targetCount,
    );
  }

  // Convert from domain entity
  factory MissionModel.fromEntity(MissionEntity entity) {
    return MissionModel(
      type: HiveMissionType.values[entity.type.index],
      difficulty: entity.difficulty,
      targetCount: entity.targetCount,
    );
  }
}
