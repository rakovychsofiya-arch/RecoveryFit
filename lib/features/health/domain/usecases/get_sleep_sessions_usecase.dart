import '../entities/sleep_session.dart';
import '../repositories/health_repository.dart';

class GetSleepSessionsUseCase {
  final HealthRepository repository;

  const GetSleepSessionsUseCase(this.repository);

  Future<List<SleepSession>> call({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await repository.getSleepSessions(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
