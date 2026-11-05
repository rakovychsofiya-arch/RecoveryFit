// features/health/domain/entities/health_metric.dart
class HealthMetric {
  final DateTime date;
  final int stepsCount;
  final double activeCalories; // Спалені калорії за день

  const HealthMetric({
    required this.date,
    required this.stepsCount,
    required this.activeCalories,
  });
}