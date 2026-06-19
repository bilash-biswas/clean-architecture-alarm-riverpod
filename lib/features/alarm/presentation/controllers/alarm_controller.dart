import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/alarm_entity.dart';
import '../../domain/usecases/get_alarms.dart';
import '../../domain/usecases/save_alarm.dart';
import '../../domain/usecases/delete_alarm.dart';
import '../../../../core/services/providers.dart';

class AlarmController extends StateNotifier<List<AlarmEntity>> {
  final GetAlarms _getAlarms;
  final SaveAlarm _saveAlarm;
  final DeleteAlarm _deleteAlarm;

  AlarmController(this._getAlarms, this._saveAlarm, this._deleteAlarm) : super([]) {
    loadAlarms();
  }

  Future<void> loadAlarms() async {
    try {
      final list = await _getAlarms();
      // Sort alarms chronologically by time of day (hour and minute)
      list.sort((a, b) {
        final aMin = a.dateTime.hour * 60 + a.dateTime.minute;
        final bMin = b.dateTime.hour * 60 + b.dateTime.minute;
        return aMin.compareTo(bMin);
      });
      state = list;
    } catch (e) {
      // Handle or log error
    }
  }

  Future<void> addAlarm(AlarmEntity alarm) async {
    await _saveAlarm(alarm);
    await loadAlarms();
  }

  Future<void> updateAlarm(AlarmEntity alarm) async {
    await _saveAlarm(alarm);
    await loadAlarms();
  }

  Future<void> delete(int id) async {
    await _deleteAlarm(id);
    await loadAlarms();
  }

  Future<void> toggleAlarm(int id, bool enabled) async {
    try {
      final alarm = state.firstWhere((a) => a.id == id);
      final updated = alarm.copyWith(isEnabled: enabled);
      await _saveAlarm(updated);
      await loadAlarms();
    } catch (e) {
      // Alarm not found or exception scheduled
    }
  }

  Future<void> snoozeAlarm(AlarmEntity alarm) async {
    if (alarm.currentSnoozeCount >= alarm.maxSnoozeCount) {
      // Can't snooze anymore
      return;
    }

    final newDateTime = DateTime.now().add(Duration(minutes: alarm.snoozeDurationMinutes));
    final snoozed = alarm.copyWith(
      dateTime: newDateTime,
      currentSnoozeCount: alarm.currentSnoozeCount + 1,
      isEnabled: true,
    );

    await _saveAlarm(snoozed);
    await loadAlarms();
  }
}

final alarmControllerProvider = StateNotifierProvider<AlarmController, List<AlarmEntity>>((ref) {
  final getAlarms = ref.watch(getAlarmsUseCaseProvider);
  final saveAlarm = ref.watch(saveAlarmUseCaseProvider);
  final deleteAlarm = ref.watch(deleteAlarmUseCaseProvider);
  return AlarmController(getAlarms, saveAlarm, deleteAlarm);
});
