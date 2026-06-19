import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StopwatchState {
  final Duration elapsedTime;
  final bool isRunning;
  final List<Duration> laps;

  const StopwatchState({
    this.elapsedTime = Duration.zero,
    this.isRunning = false,
    this.laps = const [],
  });

  StopwatchState copyWith({
    Duration? elapsedTime,
    bool? isRunning,
    List<Duration>? laps,
  }) {
    return StopwatchState(
      elapsedTime: elapsedTime ?? this.elapsedTime,
      isRunning: isRunning ?? this.isRunning,
      laps: laps ?? this.laps,
    );
  }
}

class StopwatchController extends StateNotifier<StopwatchState> {
  Timer? _timer;
  DateTime? _startTime;
  Duration _accumulatedTime = Duration.zero;

  StopwatchController() : super(const StopwatchState());

  void start() {
    if (state.isRunning) return;

    _startTime = DateTime.now();
    state = state.copyWith(isRunning: true);

    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_startTime != null) {
        final elapsed = _accumulatedTime + DateTime.now().difference(_startTime!);
        state = state.copyWith(elapsedTime: elapsed);
      }
    });
  }

  void pause() {
    if (!state.isRunning) return;

    _timer?.cancel();
    _timer = null;

    if (_startTime != null) {
      _accumulatedTime += DateTime.now().difference(_startTime!);
    }
    _startTime = null;
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _startTime = null;
    _accumulatedTime = Duration.zero;
    state = const StopwatchState();
  }

  void lap() {
    final currentLaps = List<Duration>.from(state.laps);
    currentLaps.add(state.elapsedTime);
    state = state.copyWith(laps: currentLaps);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final stopwatchControllerProvider =
    StateNotifierProvider<StopwatchController, StopwatchState>((ref) {
  return StopwatchController();
});
