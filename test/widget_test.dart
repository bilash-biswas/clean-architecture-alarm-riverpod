import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_app/core/utils/alarm_utils.dart';
import 'package:alarm_app/features/stopwatch/presentation/controllers/stopwatch_controller.dart';
import 'package:alarm_app/features/timer/presentation/controllers/timer_controller.dart';
import 'package:alarm_app/core/services/alarm_service.dart';
import 'package:alarm_app/core/services/database_service.dart';
import 'package:alarm_app/features/world_clock/presentation/controllers/world_clock_controller.dart';
import 'package:alarm_app/features/world_clock/domain/entities/city_entity.dart';
import 'package:alarm_app/features/world_clock/data/models/city_model.dart';
import 'package:alarm_app/features/sleep/presentation/controllers/sleep_log_controller.dart';
import 'package:alarm_app/features/sleep/data/models/sleep_log_model.dart';

void main() {
  group('AlarmUtils calculateNextOccurrence Tests', () {
    test('Non-repeating alarm: future time same day', () {
      final now = DateTime.now();
      
      // If we are before 23:00, we can schedule a future alarm today
      if (now.hour < 23) {
        final futureTime = DateTime(now.year, now.month, now.day, now.hour + 1, now.minute);
        final nextTime = AlarmUtils.calculateNextOccurrence(futureTime, []);
        
        expect(nextTime.hour, futureTime.hour);
        expect(nextTime.minute, futureTime.minute);
        expect(nextTime.day, now.day);
      } else {
        // If it is 23:00 or later, try scheduling for 23:59 if minutes allow
        final futureTime = DateTime(now.year, now.month, now.day, 23, 59);
        if (now.isBefore(futureTime)) {
          final nextTime = AlarmUtils.calculateNextOccurrence(futureTime, []);
          expect(nextTime.hour, 23);
          expect(nextTime.minute, 59);
          expect(nextTime.day, now.day);
        }
      }
    });

    test('Non-repeating alarm: past time schedules tomorrow', () {
      final now = DateTime.now();
      
      // If we are past 00:00, we can schedule a past alarm today (which wraps to tomorrow)
      if (now.hour > 0) {
        final pastTime = DateTime(now.year, now.month, now.day, now.hour - 1, now.minute);
        final nextTime = AlarmUtils.calculateNextOccurrence(pastTime, []);
        
        expect(nextTime.hour, pastTime.hour);
        expect(nextTime.minute, pastTime.minute);
        
        final tomorrow = now.add(const Duration(days: 1));
        expect(nextTime.day, tomorrow.day);
      }
    });
  });

  group('StopwatchController Tests', () {
    test('Initial state is correct', () {
      final controller = StopwatchController();
      expect(controller.debugState.elapsedTime, Duration.zero);
      expect(controller.debugState.isRunning, false);
      expect(controller.debugState.laps, isEmpty);
      controller.dispose();
    });

    test('Start and pause changes running state', () {
      final controller = StopwatchController();
      expect(controller.debugState.isRunning, false);

      controller.start();
      expect(controller.debugState.isRunning, true);

      controller.pause();
      expect(controller.debugState.isRunning, false);
      controller.dispose();
    });

    test('Lap records current elapsed time', () {
      final controller = StopwatchController();
      controller.start();
      controller.lap();
      expect(controller.debugState.laps, hasLength(1));

      controller.lap();
      expect(controller.debugState.laps, hasLength(2));
      controller.dispose();
    });

    test('Reset clears stopwatch state', () {
      final controller = StopwatchController();
      controller.start();
      controller.lap();
      
      controller.pause();
      controller.reset();
      
      expect(controller.debugState.elapsedTime, Duration.zero);
      expect(controller.debugState.isRunning, false);
      expect(controller.debugState.laps, isEmpty);
      controller.dispose();
    });
  });

  group('TimerController Tests', () {
    late FakeAlarmService fakeAlarmService;

    setUp(() {
      fakeAlarmService = FakeAlarmService();
    });

    test('Initial state is correct', () {
      final controller = TimerController(fakeAlarmService);
      expect(controller.debugState.remainingTime, const Duration(minutes: 5));
      expect(controller.debugState.presetTime, const Duration(minutes: 5));
      expect(controller.debugState.isRunning, false);
      expect(controller.debugState.isFinished, false);
      controller.dispose();
    });

    test('setDuration updates state correctly', () {
      final controller = TimerController(fakeAlarmService);
      controller.setDuration(const Duration(minutes: 10));
      
      expect(controller.debugState.remainingTime, const Duration(minutes: 10));
      expect(controller.debugState.presetTime, const Duration(minutes: 10));
      controller.dispose();
    });

    test('Start and pause updates running state', () async {
      final controller = TimerController(fakeAlarmService);
      controller.setDuration(const Duration(seconds: 30));
      
      await controller.start();
      expect(controller.debugState.isRunning, true);
      
      await controller.pause();
      expect(controller.debugState.isRunning, false);
      controller.dispose();
    });
  });

  group('WorldClockController Tests', () {
    late FakeDatabaseService fakeDb;

    setUp(() {
      fakeDb = FakeDatabaseService();
    });

    test('Initializes default cities if empty', () {
      final controller = WorldClockController(fakeDb);
      
      // Default cities: London, New York, Tokyo, Sydney (4 cities)
      expect(controller.debugState.cities, hasLength(4));
      expect(controller.debugState.cities.first.name, 'London');
      controller.dispose();
    });

    test('Can add a new city to the list', () async {
      final controller = WorldClockController(fakeDb);
      const paris = CityEntity(id: 'paris', name: 'Paris', country: 'France', timezoneOffset: 1.0);
      
      await controller.addCity(paris);
      
      expect(controller.debugState.cities, hasLength(5));
      expect(controller.debugState.cities.any((c) => c.id == 'paris'), true);
      controller.dispose();
    });

    test('Can delete a city from the list', () async {
      final controller = WorldClockController(fakeDb);
      expect(controller.debugState.cities, hasLength(4));
      
      await controller.removeCity('london');
      
      expect(controller.debugState.cities, hasLength(3));
      expect(controller.debugState.cities.any((c) => c.id == 'london'), false);
      controller.dispose();
    });
  });

  group('SleepLogController Tests', () {
    late FakeDatabaseService fakeDb;

    setUp(() {
      fakeDb = FakeDatabaseService();
    });

    test('Logs mood check-in and computes average', () async {
      final controller = SleepLogController(fakeDb);
      expect(controller.debugState.logs, isEmpty);
      
      // Log rating: 4 (Refreshed)
      await controller.logWakeUpQuality(4);
      expect(controller.debugState.logs, hasLength(1));
      expect(controller.getAverageScore(), 4.0);
      expect(controller.getAverageMoodLabel(), contains('Refreshed'));

      // Log rating: 2 (Tired)
      await controller.logWakeUpQuality(2);
      expect(controller.debugState.logs, hasLength(2));
      // Average score is (4 + 2) / 2 = 3.0
      expect(controller.getAverageScore(), 3.0);
      expect(controller.getAverageMoodLabel(), contains('Good'));
      controller.dispose();
    });
  });
}

class FakeAlarmService extends AlarmService {
  @override
  Future<bool> scheduleAlarm(dynamic alarm) async => true;
  @override
  Future<bool> cancelAlarm(int id) async => true;
}

class FakeDatabaseService extends DatabaseService {
  final List<CityModel> _cities = [];
  final List<SleepLogModel> _logs = [];

  @override
  Future<void> init() async {}

  @override
  List<CityModel> getCities() => _cities;

  @override
  Future<void> saveCity(CityModel city) async {
    _cities.removeWhere((c) => c.id == city.id);
    _cities.add(city);
  }

  @override
  Future<void> deleteCity(String id) async {
    _cities.removeWhere((c) => c.id == id);
  }

  @override
  List<SleepLogModel> getSleepLogs() => _logs;

  @override
  Future<void> saveSleepLog(SleepLogModel log) async {
    _logs.add(log);
  }
}



