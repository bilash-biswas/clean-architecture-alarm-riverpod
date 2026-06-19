import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription? _subscription;
  DateTime? _lastShakeTime;

  // Listen for device shake events
  void startShakeDetection({
    required Function() onShakeDetected,
    double threshold = 12.0, // Force threshold
    Duration debounceDuration = const Duration(milliseconds: 500),
  }) {
    stopShakeDetection();

    _subscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      // Calculate acceleration magnitude
      final double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (magnitude >= threshold) {
        final now = DateTime.now();
        if (_lastShakeTime == null || now.difference(_lastShakeTime!) > debounceDuration) {
          _lastShakeTime = now;
          onShakeDetected();
        }
      }
    });
  }

  // Stop listening to accelerometer
  void stopShakeDetection() {
    _subscription?.cancel();
    _subscription = null;
    _lastShakeTime = null;
  }
}
