import '../../domain/entities/alarm_entity.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../../../../core/services/database_service.dart';
import '../models/alarm_model.dart';

class AlarmRepositoryImpl implements AlarmRepository {
  final DatabaseService _dbService;

  AlarmRepositoryImpl(this._dbService);

  @override
  Future<List<AlarmEntity>> getAlarms() async {
    final models = _dbService.getAlarms();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveAlarm(AlarmEntity alarm) async {
    final model = AlarmModel.fromEntity(alarm);
    await _dbService.saveAlarm(model);
  }

  @override
  Future<void> deleteAlarm(int id) async {
    await _dbService.deleteAlarm(id);
  }
}
