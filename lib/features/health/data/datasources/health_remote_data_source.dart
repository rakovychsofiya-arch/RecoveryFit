import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../../domain/entities/health_metric.dart';
import '../../domain/entities/sleep_session.dart';

abstract class HealthRemoteDataSource {
  Future<bool> requestPermissions();
  Future<HealthMetric> getDailyMetric(DateTime date);
  Future<List<SleepSession>> getSleepSessions(DateTime start, DateTime end);
}

class HealthRemoteDataSourceImpl implements HealthRemoteDataSource {
  final Health health;

  HealthRemoteDataSourceImpl({Health? healthInstance})
      : health = healthInstance ?? Health();

  final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
  ];

  @override
  Future<bool> requestPermissions() async {
    try {
      await health.configure();
      final permissions = _types.map((e) => HealthDataAccess.READ).toList();
      return await health.requestAuthorization(_types, permissions: permissions);
    } catch (e) {
      debugPrint('Помилка авторизації Health Connect: $e');
      return false;
    }
  }

  @override
  Future<HealthMetric> getDailyMetric(DateTime date) async {
    await health.configure();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final steps = await health.getTotalStepsInInterval(startOfDay, endOfDay) ?? 0;

    // Отримання спалених калорій
    double calories = 0.0;
    try {
      final calorieData = await health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: endOfDay,
      );
      for (var point in calorieData) {
        final val = point.value;
        if (val is NumericHealthValue) {
          calories += val.numericValue.toDouble();
        }
      }
    } catch (e) {
      debugPrint('Не вдалося зчитати калорії: $e');
    }

    return HealthMetric(
      date: startOfDay,
      stepsCount: steps,
      activeCalories: calories,
    );
  }

  @override
  Future<List<SleepSession>> getSleepSessions(DateTime start, DateTime end) async {
    await health.configure();

    final sleepTypes = [
      HealthDataType.SLEEP_SESSION,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
      HealthDataType.SLEEP_LIGHT,
    ];

    List<HealthDataPoint> rawData = [];
    try {
      rawData = await health.getHealthDataFromTypes(
        types: sleepTypes,
        startTime: start,
        endTime: end,
      );
    } catch (e) {
      debugPrint('Не вдалося зчитати дані сну: $e');
    }

    Duration deepSleep = Duration.zero;
    Duration remSleep = Duration.zero;
    Duration lightSleep = Duration.zero;
    Duration totalSessionDuration = Duration.zero;

    DateTime? sessionStart;
    DateTime? sessionEnd;

    for (var point in rawData) {
      final duration = point.dateTo.difference(point.dateFrom);
      switch (point.type) {
        case HealthDataType.SLEEP_DEEP:
          deepSleep += duration;
          break;
        case HealthDataType.SLEEP_REM:
          remSleep += duration;
          break;
        case HealthDataType.SLEEP_LIGHT:
          lightSleep += duration;
          break;
        case HealthDataType.SLEEP_SESSION:
          totalSessionDuration += duration;
          if (sessionStart == null || point.dateFrom.isBefore(sessionStart)) {
            sessionStart = point.dateFrom;
          }
          if (sessionEnd == null || point.dateTo.isAfter(sessionEnd)) {
            sessionEnd = point.dateTo;
          }
          break;
        default:
          break;
      }
    }

    // Якщо сесій не виявлено явно, але є фази сну (наприклад, годинник зберіг фази)
    if (totalSessionDuration == Duration.zero) {
      totalSessionDuration = deepSleep + remSleep + lightSleep;
    }

    if (totalSessionDuration == Duration.zero) {
      return [];
    }

    return [
      SleepSession(
        startTime: sessionStart ?? start,
        endTime: sessionEnd ?? end,
        totalDuration: totalSessionDuration,
        deepSleep: deepSleep,
        remSleep: remSleep,
        lightSleep: lightSleep,
      )
    ];
  }
}
