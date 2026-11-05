import 'workout_enums.dart';
import 'workout_exercise.dart';

// domain/entities/workout_session.dart
sealed class WorkoutSession {
  final String id;
  final String title;
  final DateTime date;
  final Duration? restTimerDuration;
  final int? caloriesBurned;
  final int? avgHeartRate;

  const WorkoutSession({
    required this.id,
    required this.title,
    required this.date,
    this.restTimerDuration,
    this.caloriesBurned,
    this.avgHeartRate,
  });
}

// 1. Силове тренування
class StrengthWorkoutSession extends WorkoutSession {
  final List<WorkoutExercise> exercises;
  

  const StrengthWorkoutSession({
    required super.id,
    required super.title,
    required super.date,
    super.restTimerDuration,
    super.caloriesBurned,
    super.avgHeartRate,
    required this.exercises,
  });
}

// 2. Кардіо тренування
class CardioWorkoutSession extends WorkoutSession {
  final double distanceInKm;
  final int durationMinutes;

  const CardioWorkoutSession({
    required super.id,
    required super.title,
    required super.date,
    required this.distanceInKm,
    required this.durationMinutes,
    super.restTimerDuration,
    super.caloriesBurned,
    super.avgHeartRate,
  });
}

// 3. Розтяжка
class StretchingWorkoutSession extends WorkoutSession {
  final int durationMinutes;
  final int durationMinutes;

  const StretchingWorkoutSession({
    required super.id,
    required super.title,
    required super.date,
    required this.durationMinutes,
    required this.targetMuscleGroup,
    super.restTimerDuration,
    super.caloriesBurned,
    super.avgHeartRate,
  });
}