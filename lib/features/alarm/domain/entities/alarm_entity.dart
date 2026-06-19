import 'mission_entity.dart';

class AlarmEntity {
  final int id;
  final DateTime dateTime;
  final String label;
  final List<int> repeatDays; // Days of the week (1 = Monday, 7 = Sunday). Empty list means one-time.
  final bool isEnabled;
  final int snoozeDurationMinutes;
  final int maxSnoozeCount;
  final int currentSnoozeCount;
  final String audioPath;
  final double volume;
  final bool vibrate;
  final int fadeDurationSeconds;
  final MissionEntity mission;

  const AlarmEntity({
    required this.id,
    required this.dateTime,
    this.label = 'Alarm',
    this.repeatDays = const [],
    this.isEnabled = true,
    this.snoozeDurationMinutes = 5,
    this.maxSnoozeCount = 3,
    this.currentSnoozeCount = 0,
    this.audioPath = 'assets/audio/alarm.wav',
    this.volume = 0.8,
    this.vibrate = true,
    this.fadeDurationSeconds = 10,
    this.mission = const MissionEntity(type: MissionType.none),
  });

  AlarmEntity copyWith({
    int? id,
    DateTime? dateTime,
    String? label,
    List<int>? repeatDays,
    bool? isEnabled,
    int? snoozeDurationMinutes,
    int? maxSnoozeCount,
    int? currentSnoozeCount,
    String? audioPath,
    double? volume,
    bool? vibrate,
    int? fadeDurationSeconds,
    MissionEntity? mission,
  }) {
    return AlarmEntity(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      label: label ?? this.label,
      repeatDays: repeatDays ?? this.repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
      snoozeDurationMinutes: snoozeDurationMinutes ?? this.snoozeDurationMinutes,
      maxSnoozeCount: maxSnoozeCount ?? this.maxSnoozeCount,
      currentSnoozeCount: currentSnoozeCount ?? this.currentSnoozeCount,
      audioPath: audioPath ?? this.audioPath,
      volume: volume ?? this.volume,
      vibrate: vibrate ?? this.vibrate,
      fadeDurationSeconds: fadeDurationSeconds ?? this.fadeDurationSeconds,
      mission: mission ?? this.mission,
    );
  }

  // Helper to check if repeating
  bool get isRepeating => repeatDays.isNotEmpty;

  // Formatted repeat text
  String get repeatDaysText {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.length == 5 && repeatDays.every((day) => day >= 1 && day <= 5)) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 && repeatDays.every((day) => day == 6 || day == 7)) {
      return 'Weekends';
    }
    
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = List<int>.from(repeatDays)..sort();
    return sorted.map((d) => dayNames[d - 1]).join(', ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          dateTime == other.dateTime &&
          label == other.label &&
          repeatDays == other.repeatDays &&
          isEnabled == other.isEnabled &&
          snoozeDurationMinutes == other.snoozeDurationMinutes &&
          maxSnoozeCount == other.maxSnoozeCount &&
          currentSnoozeCount == other.currentSnoozeCount &&
          audioPath == other.audioPath &&
          volume == other.volume &&
          vibrate == other.vibrate &&
          fadeDurationSeconds == other.fadeDurationSeconds &&
          mission == other.mission;

  @override
  int get hashCode =>
      id.hashCode ^
      dateTime.hashCode ^
      label.hashCode ^
      repeatDays.hashCode ^
      isEnabled.hashCode ^
      snoozeDurationMinutes.hashCode ^
      maxSnoozeCount.hashCode ^
      currentSnoozeCount.hashCode ^
      audioPath.hashCode ^
      volume.hashCode ^
      vibrate.hashCode ^
      fadeDurationSeconds.hashCode ^
      mission.hashCode;
}
