import '../entities/health_metric.dart';
import '../entities/sleep_session.dart';

abstract class HealthRepository {
  /// Отримати метрики за конкретний день (кроки, добові калорії)
  Future<HealthMetric?> getDailyHealthMetric(DateTime date);

  /// Отримати сесії сну за обраний діапазон дат
  Future<List<SleepSession>> getSleepSessions({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Синхронізувати/витягнути свіжі дані з Health Connect / Apple Health
  Future<void> syncHealthData();
}