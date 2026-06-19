import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/providers.dart';

class SleepState {
  final bool isPlaying;
  final String selectedSound;
  final double volume;
  final Duration? remainingTimer;

  const SleepState({
    this.isPlaying = false,
    this.selectedSound = 'assets/audio/ambient_rain.wav',
    this.volume = 0.5,
    this.remainingTimer,
  });

  SleepState copyWith({
    bool? isPlaying,
    String? selectedSound,
    double? volume,
    Duration? remainingTimer,
    bool clearTimer = false,
  }) {
    return SleepState(
      isPlaying: isPlaying ?? this.isPlaying,
      selectedSound: selectedSound ?? this.selectedSound,
      volume: volume ?? this.volume,
      remainingTimer: clearTimer ? null : (remainingTimer ?? this.remainingTimer),
    );
  }
}

class SleepController extends StateNotifier<SleepState> {
  final AudioService _audioService;
  Timer? _countdownTimer;

  SleepController(this._audioService) : super(const SleepState()) {
    _audioService.playerStateStream.listen((playerState) {
      if (mounted) {
        state = state.copyWith(isPlaying: playerState.playing);
      }
    });
  }

  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await _audioService.stop();
      _cancelCountdown();
      state = state.copyWith(isPlaying: false, clearTimer: true);
    } else {
      await _audioService.playAmbient(state.selectedSound, volume: state.volume);
      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> selectSound(String soundPath) async {
    state = state.copyWith(selectedSound: soundPath);
    if (state.isPlaying) {
      await _audioService.playAmbient(soundPath, volume: state.volume);
    }
  }

  Future<void> setVolume(double volume) async {
    state = state.copyWith(volume: volume);
    await _audioService.setVolume(volume);
  }

  void startTimer(Duration duration) {
    _cancelCountdown();

    _audioService.startSleepTimer(duration, initialVolume: state.volume);
    state = state.copyWith(remainingTimer: duration);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final currentRemaining = state.remainingTimer;
      if (currentRemaining == null || currentRemaining.inSeconds <= 0 || !_audioService.isPlaying) {
        _cancelCountdown();
        state = state.copyWith(clearTimer: true);
      } else {
        state = state.copyWith(remainingTimer: currentRemaining - const Duration(seconds: 1));
      }
    });
  }

  void stopTimer() {
    _audioService.stop();
    _cancelCountdown();
    state = state.copyWith(clearTimer: true);
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void dispose() {
    _cancelCountdown();
    super.dispose();
  }
}

final sleepControllerProvider = StateNotifierProvider<SleepController, SleepState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return SleepController(audioService);
});
