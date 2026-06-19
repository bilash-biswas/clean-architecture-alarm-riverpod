enum MissionType {
  none,
  math,
  shake,
  captcha,
  memory,
}

class MissionEntity {
  final MissionType type;
  final int difficulty; // 1 = Easy, 2 = Medium, 3 = Hard
  final int targetCount; // e.g., number of math equations, count of shakes

  const MissionEntity({
    required this.type,
    this.difficulty = 1,
    this.targetCount = 5,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissionEntity &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          difficulty == other.difficulty &&
          targetCount == other.targetCount;

  @override
  int get hashCode => type.hashCode ^ difficulty.hashCode ^ targetCount.hashCode;
}
