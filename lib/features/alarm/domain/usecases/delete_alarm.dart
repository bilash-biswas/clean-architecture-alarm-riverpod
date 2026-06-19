import '../repositories/alarm_repository.dart';
import '../../../../core/services/alarm_service.dart';

class DeleteAlarm {
  final AlarmRepository _repository;
  final AlarmService _alarmService;

  DeleteAlarm(this._repository, this._alarmService);

  Future<void> call(int id) async {
    // Cancel the alarm natively
    await _alarmService.cancelAlarm(id);
    
    // Delete from local DB
    await _repository.deleteAlarm(id);
  }
}
