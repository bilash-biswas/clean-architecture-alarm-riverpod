class AlarmUtils {
  /// Calculates the next occurrence of an alarm.
  /// [selectedTime] should contain the target hour and minute.
  /// [repeatDays] is a list of weekdays (1 = Monday, 7 = Sunday). If empty, schedules for the next possible hour/minute (today or tomorrow).
  static DateTime calculateNextOccurrence(DateTime selectedTime, List<int> repeatDays) {
    final now = DateTime.now();
    
    // Construct target for today with the selected hour and minute, resetting seconds & milliseconds
    var target = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
      0,
      0,
      0,
    );

    if (repeatDays.isEmpty) {
      // Non-repeating alarm: if it has passed today, schedule for tomorrow
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }
      return target;
    }

    // Repeating alarm: find the closest future weekday matching repeatDays
    int currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
    int shortestDiff = 8;

    for (int day in repeatDays) {
      int diff = day - currentWeekday;
      if (diff < 0) {
        diff += 7;
      } else if (diff == 0) {
        // Today, check if time has already passed
        if (target.isBefore(now)) {
          diff = 7; // Schedule for next week's occurrence
        }
      }
      if (diff < shortestDiff) {
        shortestDiff = diff;
      }
    }

    return target.add(Duration(days: shortestDiff));
  }
}
