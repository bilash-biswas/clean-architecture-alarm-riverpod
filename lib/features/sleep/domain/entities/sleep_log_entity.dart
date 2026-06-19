class SleepLogEntity {
  final DateTime date;
  final int rating; // 1 = Exhausted, 2 = Tired, 3 = Good, 4 = Refreshed

  const SleepLogEntity({
    required this.date,
    required this.rating,
  });

  String get emoji {
    switch (rating) {
      case 4:
        return '🤩';
      case 3:
        return '🙂';
      case 2:
        return '🥱';
      case 1:
      default:
        return '😫';
    }
  }

  String get label {
    switch (rating) {
      case 4:
        return 'Refreshed';
      case 3:
        return 'Good';
      case 2:
        return 'Tired';
      case 1:
      default:
        return 'Exhausted';
    }
  }
}
