import 'workout_enums.dart';
import 'workout_exercise.dart';

// domain/entities/workout_session.dart
sealed class WorkoutSession {
  final String id;
  final String title;
  final DateTime date;
  final Duration? restTimerDuration;

  const WorkoutSession({
    required this.id,
    required this.title,
    required this.date,
    this.restTimerDuration,
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
    required this.exercises,
  });
}

// 2. Кардіо тренування
class CardioWorkoutSession extends WorkoutSession {
  final double distanceInKm;
  final int durationMinutes;
  final int? avgHeartRate;

  const CardioWorkoutSession({
    required super.id,
    required super.title,
    required super.date,
    required this.distanceInKm,
    required this.durationMinutes,
    this.avgHeartRate,
  });
}

// 3. Розтяжка
class StretchingWorkoutSession extends WorkoutSession {
  final int durationMinutes;
  final String targetMuscleGroup;

  const StretchingWorkoutSession({
    required super.id,
    required super.title,
    required super.date,
    required this.durationMinutes,
    required this.targetMuscleGroup,
  });
}