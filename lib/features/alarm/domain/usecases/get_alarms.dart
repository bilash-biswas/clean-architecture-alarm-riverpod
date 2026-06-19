import '../entities/alarm_entity.dart';
import '../repositories/alarm_repository.dart';

class GetAlarms {
  final AlarmRepository _repository;

  GetAlarms(this._repository);

  Future<List<AlarmEntity>> call() async {
    return await _repository.getAlarms();
  }
}
