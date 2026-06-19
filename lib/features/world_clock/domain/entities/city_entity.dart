class CityEntity {
  final String id;
  final String name;
  final String country;
  final double timezoneOffset; // GMT Offset in hours (e.g., -5.0, 5.5, 9.0)

  const CityEntity({
    required this.id,
    required this.name,
    required this.country,
    required this.timezoneOffset,
  });

  CityEntity copyWith({
    String? id,
    String? name,
    String? country,
    double? timezoneOffset,
  }) {
    return CityEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      timezoneOffset: timezoneOffset ?? this.timezoneOffset,
    );
  }
}
