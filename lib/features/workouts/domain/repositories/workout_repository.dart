import '../entities/exercise.dart';
import '../entities/workout_session.dart';
import '../entities/workout_template.dart';

abstract class WorkoutRepository {
  /// Отримати список усіх проведених тренувань (історія)
  Future<List<WorkoutSession>> getWorkouts();

  /// Отримати конкретне тренування за ID
  Future<WorkoutSession?> getWorkoutById(String id);

  /// Зберегти нове або оновлене тренування
  Future<void> saveWorkout(WorkoutSession session);

  /// Видалити тренування за ID
  Future<void> deleteWorkout(String id);

  /// Каталог вправ
  Future<List<Exercise>> getExercises({String? category});

  /// Шаблони тренувань (програми)
  Future<List<WorkoutTemplate>> getTemplates();

  /// Отримати шаблон за ID
  Future<WorkoutTemplate?> getTemplateById(String id);

  /// Зберегти або оновити шаблон тренування
  Future<void> saveTemplate(WorkoutTemplate template);

  /// Видалити шаблон тренування
  Future<void> deleteTemplate(String id);
}
