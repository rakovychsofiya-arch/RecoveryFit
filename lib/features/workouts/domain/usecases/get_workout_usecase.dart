import '../entities/workout_session.dart';
import '../repositories/workout_repository.dart';

class GetWorkoutsUseCase {
  final WorkoutRepository repository;

  const GetWorkoutsUseCase(this.repository);

  Future<List<WorkoutSession>> call() async {
    return await repository.getWorkouts();
  }
}