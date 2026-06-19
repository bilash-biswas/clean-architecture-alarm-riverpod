import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/providers.dart';

class SettingsState {
  final bool isDarkMode;
  final int defaultSnoozeDuration;
  final double defaultAlarmVolume;
  final int fadeInDuration;

  const SettingsState({
    required this.isDarkMode,
    required this.defaultSnoozeDuration,
    required this.defaultAlarmVolume,
    required this.fadeInDuration,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    int? defaultSnoozeDuration,
    double? defaultAlarmVolume,
    int? fadeInDuration,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      defaultSnoozeDuration: defaultSnoozeDuration ?? this.defaultSnoozeDuration,
      defaultAlarmVolume: defaultAlarmVolume ?? this.defaultAlarmVolume,
      fadeInDuration: fadeInDuration ?? this.fadeInDuration,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  final DatabaseService _db;

  SettingsController(this._db)
      : super(SettingsState(
          isDarkMode: _db.isDarkMode,
          defaultSnoozeDuration: _db.defaultSnoozeDuration,
          defaultAlarmVolume: _db.defaultAlarmVolume,
          fadeInDuration: _db.fadeInDuration,
        ));

  Future<void> toggleDarkMode() async {
    final newVal = !state.isDarkMode;
    await _db.setDarkMode(newVal);
    state = state.copyWith(isDarkMode: newVal);
  }

  Future<void> setDefaultSnoozeDuration(int minutes) async {
    await _db.setDefaultSnoozeDuration(minutes);
    state = state.copyWith(defaultSnoozeDuration: minutes);
  }

  Future<void> setDefaultAlarmVolume(double volume) async {
    await _db.setDefaultAlarmVolume(volume);
    state = state.copyWith(defaultAlarmVolume: volume);
  }

  Future<void> setFadeInDuration(int seconds) async {
    await _db.setFadeInDuration(seconds);
    state = state.copyWith(fadeInDuration: seconds);
  }
}

final settingsControllerProvider = StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return SettingsController(db);
});
