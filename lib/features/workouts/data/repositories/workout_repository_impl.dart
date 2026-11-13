import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasource/workout_local_data_source.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutLocalDataSource localDataSource;

  WorkoutRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Exercise>> getExercises({String? category}) {
    return localDataSource.getExercises(category: category);
  }

  @override
  Future<List<WorkoutTemplate>> getTemplates() {
    return localDataSource.getTemplates();
  }

  @override
  Future<WorkoutTemplate?> getTemplateById(String id) {
    return localDataSource.getTemplateById(id);
  }

  @override
  Future<void> saveTemplate(WorkoutTemplate template) {
    return localDataSource.saveTemplate(template);
  }

  @override
  Future<void> deleteTemplate(String id) {
    return localDataSource.deleteTemplate(id);
  }

  @override
  Future<List<WorkoutSession>> getWorkouts() {
    return localDataSource.getWorkouts();
  }

  @override
  Future<WorkoutSession?> getWorkoutById(String id) {
    return localDataSource.getWorkoutById(id);
  }

  @override
  Future<void> saveWorkout(WorkoutSession session) {
    return localDataSource.saveWorkout(session);
  }

  @override
  Future<void> deleteWorkout(String id) {
    return localDataSource.deleteWorkout(id);
  }
}
