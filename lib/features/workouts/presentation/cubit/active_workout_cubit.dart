import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_enums.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_set.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/usecases/save_workout_usecase.dart';
import 'active_workout_state.dart';

class ActiveWorkoutCubit extends Cubit<ActiveWorkoutState> {
  final SaveWorkoutUseCase saveWorkoutUseCase;
  final Uuid _uuid = const Uuid();
  Timer? _restTimer;
  DateTime? _timerEndTime;

  ActiveWorkoutCubit({required this.saveWorkoutUseCase})
      : super(ActiveWorkoutInitial());

  // Почати силове тренування (з шаблону або вільне)
  void startStrengthWorkout({WorkoutTemplate? template, String? title}) {
    _cancelTimer();
    final workoutTitle = title ?? template?.title ?? 'Силове тренування';

    final List<WorkoutExercise> exercises = [];
    if (template != null) {
      for (var tEx in template.exercises) {
        final List<WorkoutSet> sets = List.generate(
          tEx.defaultSets,
          (i) => WorkoutSet(
            id: _uuid.v4(),
            setNumber: i + 1,
            weight: tEx.defaultWeight,
            reps: tEx.defaultReps,
            category: SetCategory.working,
            isCompleted: false,
          ),
        );

        exercises.add(WorkoutExercise(
          id: _uuid.v4(),
          name: tEx.exerciseName,
          equipment: tEx.equipment,
          sets: sets,
        ));
      }
    }

    final session = StrengthWorkoutSession(
      id: _uuid.v4(),
      title: workoutTitle,
      date: DateTime.now(),
      exercises: exercises,
    );

    emit(ActiveWorkoutInProgress(session: session));
  }

  // Почати кардіо тренування
  void startCardioWorkout({
    required String title,
    required double distanceInKm,
    required int durationMinutes,
    int? avgHeartRate,
    int? caloriesBurned,
    String? notes,
  }) {
    _cancelTimer();
    final session = CardioWorkoutSession(
      id: _uuid.v4(),
      title: title,
      date: DateTime.now(),
      distanceInKm: distanceInKm,
      durationMinutes: durationMinutes,
      avgHeartRate: avgHeartRate,
      caloriesBurned: caloriesBurned,
      notes: notes,
    );
    emit(ActiveWorkoutInProgress(session: session));
  }

  // Почати розтяжку
  void startStretchingWorkout({
    required String title,
    required int durationMinutes,
    required String targetMuscleGroup,
    int? avgHeartRate,
    int? caloriesBurned,
    String? notes,
  }) {
    _cancelTimer();
    final session = StretchingWorkoutSession(
      id: _uuid.v4(),
      title: title,
      date: DateTime.now(),
      durationMinutes: durationMinutes,
      targetMuscleGroup: targetMuscleGroup,
      avgHeartRate: avgHeartRate,
      caloriesBurned: caloriesBurned,
      notes: notes,
    );
    emit(ActiveWorkoutInProgress(session: session));
  }

  // Додати вправу до силового тренування
  void addExercise(Exercise exercise) {
    final state = this.state;
    if (state is! ActiveWorkoutInProgress) return;
    if (state.session is! StrengthWorkoutSession) return;

    final session = state.session as StrengthWorkoutSession;
    final newExercise = WorkoutExercise(
      id: _uuid.v4(),
      exerciseId: exercise.id,
      name: exercise.name,
      equipment: exercise.equipment,
      sets: [
        WorkoutSet(
          id: _uuid.v4(),
          setNumber: 1,
          weight: 20.0,
          reps: 10,
          category: SetCategory.working,
          isCompleted: false,
        )
      ],
    );

    final updatedExercises = List<WorkoutExercise>.from(session.exercises)..add(newExercise);
    emit(state.copyWith(session: session.copyWith(exercises: updatedExercises)));
  }

  // Видалити вправу з силового тренування (якщо додали помилково)
  void removeExercise(int exerciseIndex) {
    final state = this.state;
    if (state is! ActiveWorkoutInProgress) return;
    if (state.session is! StrengthWorkoutSession) return;

    final session = state.session as StrengthWorkoutSession;
    if (exerciseIndex >= session.exercises.length) return;

    final updatedExercises = List<WorkoutExercise>.from(session.exercises)..removeAt(exerciseIndex);
    emit(state.copyWith(session: session.copyWith(exercises: updatedExercises)));
  }

  // Змінити обладнання для вправи (гантелі, штанга, тренажер, власна вага)
  void updateExerciseEquipment(int exerciseIndex, EquipmentType equipment) {
    final state = this.state;
    if (state is! ActiveWorkoutInProgress) return;
    if (state.session is! StrengthWorkoutSession) return;

    final session = state.session as StrengthWorkoutSession;
    if (exerciseIndex >= session.exercises.length) return;

    final updatedExercises = List<WorkoutExercise>.from(session.exercises);
    final target = updatedExercises[exerciseIndex];
    updatedExercises[exerciseIndex] = target.copyWith(equipment: equipment);

    emit(state.copyWith(session: session.copyWith(exercises: updatedExercises)));
  }

  // Додати підхід (сет)
  void addSet(int exerciseIndex) {
    final state = this.state;
    if (state is! ActiveWorkoutInProgress) return;
    if (state.session is! StrengthWorkoutSession) return;

    final session = state.session as StrengthWorkoutSession;
    if (exerciseIndex >= session.exercises.length) return;

    final updatedExercises = List<WorkoutExercise>.from(session.exercises);
    final targetEx = updatedExercises[exerciseIndex];
    final lastSet = targetEx.sets.isNotEmpty ? targetEx.sets.last : null;

    final newSet = WorkoutSet(
      id: _uuid.v4(),
      setNumber: targetEx.sets.length + 1,
      weight: lastSet?.weight ?? 20.0,
      reps: lastSet?.reps ?? 10,
      category: SetCategory.working,
      isCompleted: false,
    );

    final updatedSets = List<WorkoutSet>.from(targetEx.sets)..add(newSet);
    updatedExercises[exerciseIndex] = targetEx.copyWith(sets: updatedSets);

    emit(state.copyWith(session: session.copyWith(exercises: updatedExercises)));
  }

  // Видалити підхід
  void removeSet(int exerciseIndex, int setIndex) {
    final state = this.state;
    if (state is! ActiveWorkoutInProgress) return;
    if (state.session is! StrengthWorkoutSession) return;

    final session = state.session as StrengthWorkoutSession;
    if (exerciseIndex >= session.exercises.length) return;

    final updatedExercises = List<WorkoutExercise>.from(session.exercises);
    final targetEx = updatedExercises[exerciseIndex];
    if (setIndex >= targetEx.sets.length) return;

    final updatedSets = List<WorkoutSet>.from(targetEx.sets)..removeAt(setIndex);
    // Перераховуємо порядкові номери сетів
    final reindexedSets = [
      for (int i = 0; i < updatedSets.length; i++)
        updatedSets[i].copyWith(setNumber: i + 1)
    ];

    updatedExercises[exerciseIndex] = targetEx.copyWith(sets: reindexedSets);
    emit(state.copyWith(session: session.copyWith(exercises: updatedExercises)));
  }

  // Оновити підхід (вага, повторення, категорія, галочка виконано)
  void updateSet(
    int exerciseIndex,
    int setIndex, {
    double? weight,
    int? reps,
    SetCategory? category,
    bool? isCompleted,
  }) {
    final state = this.state;
    if (state is! ActiveWorkoutInProgress) return;
    if (state.session is! StrengthWorkoutSession) return;

    final session = state.session as StrengthWorkoutSession;
    if (exerciseIndex >= session.exercises.length) return;

    final updatedExercises = List<WorkoutExercise>.from(session.exercises);
    final targetEx = updatedExercises[exerciseIndex];
    if (setIndex >= targetEx.sets.length) return;

    final updatedSets = List<WorkoutSet>.from(targetEx.sets);
    final targetSet = updatedSets[setIndex];

    final updated = targetSet.copyWith(
      weight: weight,
      reps: reps,
      category: category,
      isCompleted: isCompleted,
    );
    updatedSets[setIndex] = updated;
    updatedExercises[exerciseIndex] = targetEx.copyWith(sets: updatedSets);

    // Якщо підхід щойно відмічено як виконаний — можна автоматично запропонувати запустити таймер на 60 або 90 сек
    emit(state.copyWith(session: session.copyWith(exercises: updatedExercises)));

    if (isCompleted == true && !state.isTimerRunning) {
      startRestTimer(90); // 90 секунд за замовчуванням
    }
  }

  // Опційний таймер відпочинку (працює за реальним годинником)
  void startRestTimer(int seconds) {
    _cancelTimer();
    final state = this.state;
    if (state is! ActiveWorkoutInProgress) return;

    _timerEndTime = DateTime.now().add(Duration(seconds: seconds));
    emit(state.copyWith(timerSecondsRemaining: seconds, isTimerRunning: true));

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = this.state;
      if (current is! ActiveWorkoutInProgress || _timerEndTime == null) {
        timer.cancel();
        return;
      }
      final remaining = _timerEndTime!.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        _cancelTimer();
        emit(current.copyWith(timerSecondsRemaining: 0, isTimerRunning: false));
        NotificationService.instance.showRestTimerFinishedNotification();
      } else {
        emit(current.copyWith(timerSecondsRemaining: remaining, isTimerRunning: true));
      }
    });
  }

  void stopRestTimer() {
    _cancelTimer();
    final state = this.state;
    if (state is ActiveWorkoutInProgress) {
      emit(state.copyWith(timerSecondsRemaining: 0, isTimerRunning: false));
    }
  }

  void _cancelTimer() {
    _restTimer?.cancel();
    _restTimer = null;
    _timerEndTime = null;
  }

  // Завершити та зберегти тренування
  Future<void> saveWorkout() async {
    final state = this.state;
    if (state is! ActiveWorkoutInProgress) return;

    try {
      await saveWorkoutUseCase(state.session);
      _cancelTimer();
      emit(ActiveWorkoutSaved());
    } catch (e) {
      emit(ActiveWorkoutError('Помилка збереження тренування: $e'));
    }
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}
