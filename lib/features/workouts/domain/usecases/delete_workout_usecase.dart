import '../repositories/workout_repository.dart';

class DeleteWorkoutUseCase {
  final WorkoutRepository repository;

  const DeleteWorkoutUseCase(this.repository);

  Future<void> call(String id) async {
    await repository.deleteWorkout(id);
  }
}