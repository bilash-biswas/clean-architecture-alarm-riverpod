import '../entities/alarm_entity.dart';
import '../repositories/alarm_repository.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/utils/alarm_utils.dart';

class SaveAlarm {
  final AlarmRepository _repository;
  final AlarmService _alarmService;

  SaveAlarm(this._repository, this._alarmService);

  Future<void> call(AlarmEntity alarm) async {
    if (alarm.isEnabled) {
      // Calculate next trigger time
      final nextTime = AlarmUtils.calculateNextOccurrence(alarm.dateTime, alarm.repeatDays);
      final scheduledAlarm = alarm.copyWith(
        dateTime: nextTime,
        currentSnoozeCount: 0, // Reset snooze when saving/toggling
      );

      // Schedule with native Alarm service
      final success = await _alarmService.scheduleAlarm(scheduledAlarm);
      if (success) {
        await _repository.saveAlarm(scheduledAlarm);
      } else {
        throw Exception('Failed to schedule native alarm.');
      }
    } else {
      // Cancel native alarm if disabled
      await _alarmService.cancelAlarm(alarm.id);
      await _repository.saveAlarm(alarm);
    }
  }
}
