import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../features/alarm/data/models/alarm_model.dart';
import '../../features/alarm/data/models/mission_model.dart';
import '../../features/world_clock/data/models/city_model.dart';
import '../../features/sleep/data/models/sleep_log_model.dart';

class DatabaseService {
  late Box<AlarmModel> _alarmBox;
  late Box _settingsBox;
  late Box<CityModel> _worldClockBox;
  late Box<SleepLogModel> _sleepLogsBox;

  Future<void> init() async {
    // Initialize Hive for Flutter
    await Hive.initFlutter();

    // Register Hive Adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AlarmModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MissionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HiveMissionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CityModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SleepLogModelAdapter());
    }

    // Open Boxes
    _alarmBox = await Hive.openBox<AlarmModel>(AppConstants.alarmBoxName);
    _settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
    _worldClockBox = await Hive.openBox<CityModel>('world_clock_box');
    _sleepLogsBox = await Hive.openBox<SleepLogModel>('sleep_logs_box');
  }

  // Alarms storage accessors
  List<AlarmModel> getAlarms() {
    return _alarmBox.values.toList();
  }

  Future<void> saveAlarm(AlarmModel alarm) async {
    await _alarmBox.put(alarm.id, alarm);
  }

  Future<void> deleteAlarm(int id) async {
    await _alarmBox.delete(id);
  }

  // Settings storage accessors
  bool get isDarkMode => _settingsBox.get(AppConstants.keyDarkMode, defaultValue: true);
  Future<void> setDarkMode(bool value) async {
    await _settingsBox.put(AppConstants.keyDarkMode, value);
  }

  int get defaultSnoozeDuration => _settingsBox.get(AppConstants.keyDefaultSnooze, defaultValue: 5);
  Future<void> setDefaultSnoozeDuration(int minutes) async {
    await _settingsBox.put(AppConstants.keyDefaultSnooze, minutes);
  }

  double get defaultAlarmVolume => _settingsBox.get(AppConstants.keyDefaultVolume, defaultValue: 0.8);
  Future<void> setDefaultAlarmVolume(double volume) async {
    await _settingsBox.put(AppConstants.keyDefaultVolume, volume);
  }

  int get fadeInDuration => _settingsBox.get(AppConstants.keyFadeInDuration, defaultValue: 10);
  Future<void> setFadeInDuration(int seconds) async {
    await _settingsBox.put(AppConstants.keyFadeInDuration, seconds);
  }

  // World Clock storage
  List<CityModel> getCities() {
    return _worldClockBox.values.toList();
  }

  Future<void> saveCity(CityModel city) async {
    await _worldClockBox.put(city.id, city);
  }

  Future<void> deleteCity(String id) async {
    await _worldClockBox.delete(id);
  }

  // Sleep Journal storage
  List<SleepLogModel> getSleepLogs() {
    return _sleepLogsBox.values.toList();
  }

  Future<void> saveSleepLog(SleepLogModel log) async {
    final key = "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}";
    await _sleepLogsBox.put(key, log);
  }
}
