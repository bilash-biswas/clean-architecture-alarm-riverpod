import 'dart:async';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  Timer? _fadeTimer;
  Timer? _sleepTimer;

  // Initialize the player
  Future<void> init() async {
    // Basic init if needed, just_audio loads lazily
  }

  // Play an ambient sound loop
  Future<void> playAmbient(String assetPath, {double volume = 0.5}) async {
    try {
      _cancelTimers();
      await _player.setAsset(assetPath);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(volume);
      await _player.play();
    } catch (e) {
      // Handle player error
    }
  }

  // Set current player volume
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  // Stop playback and clean up timers
  Future<void> stop() async {
    _cancelTimers();
    await _player.stop();
  }

  // Start a sleep timer that stops playback after [duration], fading out in the last 15 seconds
  void startSleepTimer(Duration duration, {double initialVolume = 0.5}) {
    _cancelTimers();
    _player.setVolume(initialVolume);

    _sleepTimer = Timer(duration, () async {
      // Begin volume fade out
      double currentVol = _player.volume;
      const fadeSteps = 15;
      final stepDuration = const Duration(seconds: 15) ~/ fadeSteps;
      final volDecrement = currentVol / fadeSteps;

      _fadeTimer = Timer.periodic(stepDuration, (timer) async {
        currentVol = (currentVol - volDecrement).clamp(0.0, 1.0);
        await _player.setVolume(currentVol);

        if (currentVol <= 0.0) {
          timer.cancel();
          await stop();
        }
      });
    });
  }

  // Cancel active timers
  void _cancelTimers() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _fadeTimer?.cancel();
    _fadeTimer = null;
  }

  // Stream of player state
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  bool get isPlaying => _player.playing;

  // Cleanup player resource
  Future<void> dispose() async {
    _cancelTimers();
    await _player.dispose();
  }
}
