import 'dart:io';
import 'package:alarm/alarm.dart';
import '../../features/alarm/domain/entities/alarm_entity.dart';

class AlarmService {
  Future<void> init() async {
    await Alarm.init();
  }

  // Set/schedule native alarm
  Future<bool> scheduleAlarm(AlarmEntity alarm) async {
    final alarmSettings = AlarmSettings(
      id: alarm.id,
      dateTime: alarm.dateTime,
      assetAudioPath: alarm.audioPath,
      loopAudio: true,
      vibrate: alarm.vibrate,
      volume: alarm.volume,
      fadeDuration: alarm.fadeDurationSeconds.toDouble(),
      warningNotificationOnKill: Platform.isIOS,
      androidFullScreenIntent: true,
      notificationSettings: NotificationSettings(
        title: alarm.label,
        body: 'Tap to solve your wake-up mission!',
        stopButton: 'Stop',
      ),
    );

    try {
      return await Alarm.set(alarmSettings: alarmSettings);
    } catch (e) {
      // Log or handle scheduling error
      return false;
    }
  }

  // Stop/cancel specific alarm
  Future<bool> cancelAlarm(int id) async {
    return await Alarm.stop(id);
  }

  // Stop all active alarms
  Future<void> stopAll() async {
    final alarms = await Alarm.getAlarms();
    for (var alarm in alarms) {
      await Alarm.stop(alarm.id);
    }
  }

  // Check if alarm is currently ringing
  Future<bool> isRinging(int id) async {
    return await Alarm.isRinging(id);
  }

  // Get ID of the currently ringing alarm, if any
  Future<int?> getActiveRingingAlarmId() async {
    try {
      final alarms = await Alarm.getAlarms();
      for (var alarm in alarms) {
        if (await Alarm.isRinging(alarm.id)) {
          return alarm.id;
        }
      }
    } catch (_) {}
    return null;
  }

  Stream<AlarmSettings>? _broadcastStream;

  // Listen to ringing stream
  Stream<AlarmSettings>? get ringStream {
    _broadcastStream ??= Alarm.ringStream.stream.asBroadcastStream();
    return _broadcastStream;
  }
}
