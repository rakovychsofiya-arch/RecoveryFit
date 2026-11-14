import '../../domain/entities/health_metric.dart';
import '../../domain/entities/sleep_session.dart';
import '../../domain/repositories/health_repository.dart';
import '../datasources/health_remote_data_source.dart';

class HealthRepositoryImpl implements HealthRepository {
  final HealthRemoteDataSource remoteDataSource;

  HealthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<HealthMetric?> getDailyHealthMetric(DateTime date) async {
    return await remoteDataSource.getDailyMetric(date);
  }

  @override
  Future<List<SleepSession>> getSleepSessions({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await remoteDataSource.getSleepSessions(startDate, endDate);
  }

  @override
  Future<void> syncHealthData() async {
    final granted = await remoteDataSource.requestPermissions();
    if (granted) {
      await remoteDataSource.getDailyMetric(DateTime.now());
    }
  }
}
