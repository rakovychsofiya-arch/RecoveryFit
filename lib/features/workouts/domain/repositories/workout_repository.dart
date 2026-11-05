import '../entities/workout_session.dart';

abstract class WorkoutRepository {
  /// Отримати список усіх проведених тренувань
  Future<List<WorkoutSession>> getWorkouts();

  /// Отримати конкретне тренування за ID
  Future<WorkoutSession?> getWorkoutById(String id);

  /// Зберегти нове або оновлене тренування
  Future<void> saveWorkout(WorkoutSession session);

  /// Видалити тренування за ID
  Future<void> deleteWorkout(String id);
}