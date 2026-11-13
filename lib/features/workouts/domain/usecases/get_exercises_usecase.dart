import '../entities/exercise.dart';
import '../repositories/workout_repository.dart';

class GetExercisesUseCase {
  final WorkoutRepository repository;

  const GetExercisesUseCase(this.repository);

  Future<List<Exercise>> call({String? category}) async {
    return await repository.getExercises(category: category);
  }
}
