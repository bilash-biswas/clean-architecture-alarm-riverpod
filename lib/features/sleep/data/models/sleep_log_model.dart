import 'package:hive/hive.dart';
import '../../domain/entities/sleep_log_entity.dart';

part 'sleep_log_model.g.dart';

@HiveType(typeId: 4)
class SleepLogModel extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final int rating;

  SleepLogModel({
    required this.date,
    required this.rating,
  });

  SleepLogEntity toEntity() {
    return SleepLogEntity(
      date: date,
      rating: rating,
    );
  }

  factory SleepLogModel.fromEntity(SleepLogEntity entity) {
    return SleepLogModel(
      date: entity.date,
      rating: entity.rating,
    );
  }
}
