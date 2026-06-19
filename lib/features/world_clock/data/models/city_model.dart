import 'package:hive/hive.dart';
import '../../domain/entities/city_entity.dart';

part 'city_model.g.dart';

@HiveType(typeId: 3)
class CityModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String country;

  @HiveField(3)
  final double timezoneOffset;

  CityModel({
    required this.id,
    required this.name,
    required this.country,
    required this.timezoneOffset,
  });

  CityEntity toEntity() {
    return CityEntity(
      id: id,
      name: name,
      country: country,
      timezoneOffset: timezoneOffset,
    );
  }

  factory CityModel.fromEntity(CityEntity entity) {
    return CityModel(
      id: entity.id,
      name: entity.name,
      country: entity.country,
      timezoneOffset: entity.timezoneOffset,
    );
  }
}
