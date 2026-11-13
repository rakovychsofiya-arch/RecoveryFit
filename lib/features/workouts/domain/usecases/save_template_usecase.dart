import '../entities/workout_template.dart';
import '../repositories/workout_repository.dart';

class SaveTemplateUseCase {
  final WorkoutRepository repository;

  const SaveTemplateUseCase(this.repository);

  Future<void> call(WorkoutTemplate template) async {
    await repository.saveTemplate(template);
  }
}
