import '../entities/workout_session.dart';
import '../repositories/workout_repository.dart';

class SaveWorkoutUseCase {
  final WorkoutRepository repository;

  const SaveWorkoutUseCase(this.repository);

  Future<void> call(WorkoutSession session) async {
    // Тут можна додати додаткові перевірки/валідацію перед збереженням
    await repository.saveWorkout(session);
  }
}