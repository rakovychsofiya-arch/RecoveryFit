import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../domain/usecases/get_templates_usecase.dart';
import '../../domain/usecases/save_template_usecase.dart';
import 'workout_templates_state.dart';

class WorkoutTemplatesCubit extends Cubit<WorkoutTemplatesState> {
  final GetTemplatesUseCase getTemplatesUseCase;
  final SaveTemplateUseCase saveTemplateUseCase;
  final WorkoutRepository repository;

  WorkoutTemplatesCubit({
    required this.getTemplatesUseCase,
    required this.saveTemplateUseCase,
    required this.repository,
  }) : super(WorkoutTemplatesInitial());

  Future<void> loadTemplates() async {
    emit(WorkoutTemplatesLoading());
    try {
      final list = await getTemplatesUseCase();
      emit(WorkoutTemplatesLoaded(list));
    } catch (e) {
      emit(WorkoutTemplatesError('Помилка завантаження шаблонів: $e'));
    }
  }

  Future<void> saveTemplate(WorkoutTemplate template) async {
    try {
      await saveTemplateUseCase(template);
      await loadTemplates();
    } catch (e) {
      emit(WorkoutTemplatesError('Помилка збереження шаблону: $e'));
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await repository.deleteTemplate(id);
      await loadTemplates();
    } catch (e) {
      emit(WorkoutTemplatesError('Помилка видалення шаблону: $e'));
    }
  }
}
