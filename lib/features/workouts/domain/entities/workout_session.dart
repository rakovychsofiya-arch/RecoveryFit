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
  final String? notes;

  const WorkoutSession({
    required this.id,
    required this.title,
    required this.date,
    this.restTimerDuration,
    this.caloriesBurned,
    this.avgHeartRate,
    this.notes,
  });

  WorkoutType get type;
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
    super.notes,
    required this.exercises,
  });

  @override
  WorkoutType get type => WorkoutType.strength;

  StrengthWorkoutSession copyWith({
    String? id,
    String? title,
    DateTime? date,
    Duration? restTimerDuration,
    int? caloriesBurned,
    int? avgHeartRate,
    String? notes,
    List<WorkoutExercise>? exercises,
  }) {
    return StrengthWorkoutSession(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      restTimerDuration: restTimerDuration ?? this.restTimerDuration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      notes: notes ?? this.notes,
      exercises: exercises ?? this.exercises,
    );
  }
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
    super.notes,
  });

  @override
  WorkoutType get type => WorkoutType.cardio;

  CardioWorkoutSession copyWith({
    String? id,
    String? title,
    DateTime? date,
    double? distanceInKm,
    int? durationMinutes,
    Duration? restTimerDuration,
    int? caloriesBurned,
    int? avgHeartRate,
    String? notes,
  }) {
    return CardioWorkoutSession(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      distanceInKm: distanceInKm ?? this.distanceInKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      restTimerDuration: restTimerDuration ?? this.restTimerDuration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      notes: notes ?? this.notes,
    );
  }
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
    super.restTimerDuration,
    super.caloriesBurned,
    super.avgHeartRate,
    super.notes,
  });

  @override
  WorkoutType get type => WorkoutType.stretching;

  StretchingWorkoutSession copyWith({
    String? id,
    String? title,
    DateTime? date,
    int? durationMinutes,
    String? targetMuscleGroup,
    Duration? restTimerDuration,
    int? caloriesBurned,
    int? avgHeartRate,
    String? notes,
  }) {
    return StretchingWorkoutSession(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      targetMuscleGroup: targetMuscleGroup ?? this.targetMuscleGroup,
      restTimerDuration: restTimerDuration ?? this.restTimerDuration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      notes: notes ?? this.notes,
    );
  }
}
