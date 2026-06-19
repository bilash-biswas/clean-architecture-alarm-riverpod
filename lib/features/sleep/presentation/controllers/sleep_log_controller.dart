import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/providers.dart';
import '../../domain/entities/sleep_log_entity.dart';
import '../../data/models/sleep_log_model.dart';

class SleepLogState {
  final List<SleepLogEntity> logs;

  const SleepLogState({this.logs = const []});

  SleepLogState copyWith({List<SleepLogEntity>? logs}) {
    return SleepLogState(logs: logs ?? this.logs);
  }
}

class SleepLogController extends StateNotifier<SleepLogState> {
  final DatabaseService _db;

  SleepLogController(this._db) : super(const SleepLogState()) {
    _loadLogs();
  }

  void _loadLogs() {
    final logModels = _db.getSleepLogs();
    state = state.copyWith(
      logs: logModels.map((m) => m.toEntity()).toList(),
    );
  }

  Future<void> logWakeUpQuality(int rating) async {
    final log = SleepLogEntity(
      date: DateTime.now(),
      rating: rating,
    );
    
    await _db.saveSleepLog(SleepLogModel.fromEntity(log));
    _loadLogs();
  }

  // Get sleep logs mapping for the last 7 days
  List<Map<String, dynamic>> getLast7DaysStats() {
    final List<Map<String, dynamic>> stats = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      
      // Find matching log in state
      SleepLogEntity? match;
      for (var log in state.logs) {
        if (log.date.year == targetDate.year &&
            log.date.month == targetDate.month &&
            log.date.day == targetDate.day) {
          match = log;
          break;
        }
      }

      final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = weekdayNames[targetDate.weekday - 1];

      stats.add({
        'dayName': dayName,
        'rating': match?.rating ?? 0, // 0 means no log
        'emoji': match?.emoji ?? '',
        'date': targetDate,
      });
    }

    return stats;
  }

  // Calculate average sleep score out of 4
  double getAverageScore() {
    if (state.logs.isEmpty) return 0.0;
    
    // Only average logs from the past 7 days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    final recentLogs = state.logs.where((log) => log.date.isAfter(sevenDaysAgo)).toList();
    if (recentLogs.isEmpty) return 0.0;

    final total = recentLogs.fold(0, (sum, log) => sum + log.rating);
    return total / recentLogs.length;
  }

  String getAverageMoodLabel() {
    final score = getAverageScore();
    if (score == 0.0) return 'No Data';
    if (score > 3.5) return 'Refreshed 🤩';
    if (score > 2.5) return 'Good 🙂';
    if (score > 1.5) return 'Tired 🥱';
    return 'Exhausted 😫';
  }
}

final sleepLogControllerProvider =
    StateNotifierProvider<SleepLogController, SleepLogState>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return SleepLogController(db);
});
