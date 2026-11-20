import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/usecases/delete_workout_usecase.dart';
import '../../domain/usecases/get_workout_usecase.dart';
import '../../domain/usecases/save_workout_usecase.dart';
import 'workout_history_state.dart';

class WorkoutHistoryCubit extends Cubit<WorkoutHistoryState> {
  final GetWorkoutsUseCase getWorkoutsUseCase;
  final DeleteWorkoutUseCase deleteWorkoutUseCase;
  final SaveWorkoutUseCase saveWorkoutUseCase;

  WorkoutHistoryCubit({
    required this.getWorkoutsUseCase,
    required this.deleteWorkoutUseCase,
    required this.saveWorkoutUseCase,
  }) : super(WorkoutHistoryInitial());

  Future<void> loadHistory() async {
    emit(WorkoutHistoryLoading());
    try {
      final list = await getWorkoutsUseCase();
      emit(WorkoutHistoryLoaded(list));
    } catch (e) {
      emit(WorkoutHistoryError('Помилка завантаження історії: $e'));
    }
  }

  Future<void> updateWorkout(WorkoutSession session) async {
    try {
      await saveWorkoutUseCase(session);
      await loadHistory();
    } catch (e) {
      emit(WorkoutHistoryError('Помилка оновлення тренування: $e'));
    }
  }

  Future<void> deleteWorkout(String id) async {
    try {
      await deleteWorkoutUseCase(id);
      await loadHistory();
    } catch (e) {
      emit(WorkoutHistoryError('Помилка видалення тренування: $e'));
    }
  }
}
