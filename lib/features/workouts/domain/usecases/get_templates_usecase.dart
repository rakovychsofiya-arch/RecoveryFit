import '../entities/workout_template.dart';
import '../repositories/workout_repository.dart';

class GetTemplatesUseCase {
  final WorkoutRepository repository;

  const GetTemplatesUseCase(this.repository);

  Future<List<WorkoutTemplate>> call() async {
    return await repository.getTemplates();
  }
}
