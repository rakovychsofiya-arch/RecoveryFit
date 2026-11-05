import '../entities/health_metric.dart';
import '../repositories/health_repository.dart';

class GetDailyHealthUseCase {
  final HealthRepository repository;

  const GetDailyHealthUseCase(this.repository);

  Future<HealthMetric?> call(DateTime date) async {
    // Автоматично синхронізуємо свіжі дані перед поверненням
    await repository.syncHealthData();
    return await repository.getDailyHealthMetric(date);
  }
}