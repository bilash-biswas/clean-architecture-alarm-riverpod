import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/services/providers.dart';
import '../../../alarm/domain/entities/alarm_entity.dart';

class TimerState {
  final Duration remainingTime;
  final Duration presetTime;
  final bool isRunning;
  final bool isFinished;

  const TimerState({
    this.remainingTime = const Duration(minutes: 5),
    this.presetTime = const Duration(minutes: 5),
    this.isRunning = false,
    this.isFinished = false,
  });

  TimerState copyWith({
    Duration? remainingTime,
    Duration? presetTime,
    bool? isRunning,
    bool? isFinished,
  }) {
    return TimerState(
      remainingTime: remainingTime ?? this.remainingTime,
      presetTime: presetTime ?? this.presetTime,
      isRunning: isRunning ?? this.isRunning,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

class TimerController extends StateNotifier<TimerState> {
  final AlarmService _alarmService;
  Timer? _tickerTimer;
  DateTime? _endTime;

  TimerController(this._alarmService) : super(const TimerState());

  static const int timerAlarmId = 999999;

  void setDuration(Duration duration) {
    if (state.isRunning) return;
    state = state.copyWith(
      presetTime: duration,
      remainingTime: duration,
      isFinished: false,
    );
  }

  Future<void> start() async {
    if (state.isRunning || state.remainingTime <= Duration.zero) return;

    _endTime = DateTime.now().add(state.remainingTime);
    state = state.copyWith(isRunning: true, isFinished: false);

    // Schedule native alarm for background support
    final alarmEntity = AlarmEntity(
      id: timerAlarmId,
      dateTime: _endTime!,
      label: 'Timer Completed',
      isEnabled: true,
      volume: 0.8,
      vibrate: true,
    );
    await _alarmService.scheduleAlarm(alarmEntity);

    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_endTime != null) {
        final diff = _endTime!.difference(DateTime.now());
        if (diff <= Duration.zero) {
          _onTimerComplete();
        } else {
          // Round up to nearest second for display
          state = state.copyWith(
            remainingTime: Duration(seconds: (diff.inMilliseconds / 1000).ceil()),
          );
        }
      }
    });
  }

  Future<void> pause() async {
    if (!state.isRunning) return;

    _tickerTimer?.cancel();
    _tickerTimer = null;
    _endTime = null;

    // Cancel native alarm
    await _alarmService.cancelAlarm(timerAlarmId);

    state = state.copyWith(isRunning: false);
  }

  Future<void> reset() async {
    _tickerTimer?.cancel();
    _tickerTimer = null;
    _endTime = null;

    // Cancel native alarm
    await _alarmService.cancelAlarm(timerAlarmId);

    state = state.copyWith(
      remainingTime: state.presetTime,
      isRunning: false,
      isFinished: false,
    );
  }

  Future<void> dismissTimer() async {
    await reset();
  }

  void _onTimerComplete() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
    _endTime = null;

    state = state.copyWith(
      remainingTime: Duration.zero,
      isRunning: false,
      isFinished: true,
    );
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }
}

final timerControllerProvider =
    StateNotifierProvider<TimerController, TimerState>((ref) {
  final alarmService = ref.watch(alarmServiceProvider);
  return TimerController(alarmService);
});
