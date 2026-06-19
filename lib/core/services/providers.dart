import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';
import 'alarm_service.dart';
import 'audio_service.dart';
import 'sensor_service.dart';
import '../../features/alarm/data/repositories/alarm_repository_impl.dart';
import '../../features/alarm/domain/repositories/alarm_repository.dart';
import '../../features/alarm/domain/usecases/get_alarms.dart';
import '../../features/alarm/domain/usecases/save_alarm.dart';
import '../../features/alarm/domain/usecases/delete_alarm.dart';

// Services
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('databaseServiceProvider must be overridden in main()');
});

final alarmServiceProvider = Provider<AlarmService>((ref) {
  return AlarmService();
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

final sensorServiceProvider = Provider<SensorService>((ref) {
  return SensorService();
});

// Repositories
final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return AlarmRepositoryImpl(db);
});

// Use cases
final getAlarmsUseCaseProvider = Provider<GetAlarms>((ref) {
  final repo = ref.watch(alarmRepositoryProvider);
  return GetAlarms(repo);
});

final saveAlarmUseCaseProvider = Provider<SaveAlarm>((ref) {
  final repo = ref.watch(alarmRepositoryProvider);
  final alarmService = ref.watch(alarmServiceProvider);
  return SaveAlarm(repo, alarmService);
});

final deleteAlarmUseCaseProvider = Provider<DeleteAlarm>((ref) {
  final repo = ref.watch(alarmRepositoryProvider);
  final alarmService = ref.watch(alarmServiceProvider);
  return DeleteAlarm(repo, alarmService);
});
