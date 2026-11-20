import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_enums.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/usecases/get_exercises_usecase.dart';
import '../cubit/active_workout_cubit.dart';
import '../cubit/active_workout_state.dart';
import '../cubit/workout_history_cubit.dart';
import '../widgets/exercise_picker_dialog.dart';

class ActiveStrengthWorkoutPage extends StatelessWidget {
  final GetExercisesUseCase getExercisesUseCase;

  const ActiveStrengthWorkoutPage({
    super.key,
    required this.getExercisesUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActiveWorkoutCubit, ActiveWorkoutState>(
      listener: (context, state) {
        if (state is ActiveWorkoutSaved) {
          context.read<WorkoutHistoryCubit>().loadHistory();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Тренування успішно збережено в історію!'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          Navigator.pop(context);
        } else if (state is ActiveWorkoutError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is! ActiveWorkoutInProgress || state.session is! StrengthWorkoutSession) {
          return const Scaffold(
            body: Center(child: Text('Немає активного тренування')),
          );
        }

        final session = state.session as StrengthWorkoutSession;
        final cubit = context.read<ActiveWorkoutCubit>();

        return Scaffold(
          appBar: AppBar(
            title: Text(session.title),
            actions: [
              TextButton.icon(
                onPressed: () {
                  _showFinishDialog(context, cubit);
                },
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Завершити',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildRestTimerBar(context, state, cubit),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Інфо про дату
              Text(
                'Дата: ${DateFormatter.formatDate(session.date)} • ${session.exercises.length} вправ',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 12),

              // Список вправ
              for (int i = 0; i < session.exercises.length; i++)
                _buildExerciseCard(context, session, i, cubit),

              const SizedBox(height: 16),
              // Кнопка додати вправу
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showModalBottomSheet<Exercise>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ExercisePickerDialog(getExercisesUseCase: getExercisesUseCase),
                  );
                  if (selected != null) {
                    cubit.addExercise(selected);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('+ Додати вправу з каталогу'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 60), // Відступ для нижньої панелі таймера
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    StrengthWorkoutSession session,
    int exIndex,
    ActiveWorkoutCubit cubit,
  ) {
    final ex = session.exercises[exIndex];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок вправи та вибір обладнання
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ex.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                // Вибір обладнання (варіації)
                DropdownButton<EquipmentType>(
                  value: ex.equipment,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                  items: EquipmentType.values.map((eq) {
                    return DropdownMenuItem(
                      value: eq,
                      child: Text(_equipmentLabel(eq.name), style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (newEq) {
                    if (newEq != null) {
                      cubit.updateExerciseEquipment(exIndex, newEq);
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 20),

            // Заголовки колонок таблиці підходів
            const Row(
              children: [
                SizedBox(width: 32, child: Text('Сет', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 3, child: Center(child: Text('Вага (кг)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                Expanded(flex: 3, child: Center(child: Text('Повтор.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                Expanded(flex: 3, child: Center(child: Text('Тип', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                SizedBox(width: 48, child: Center(child: Text('✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)))),
              ],
            ),
            const SizedBox(height: 8),

            // Рядки підходів
            for (int sIndex = 0; sIndex < ex.sets.length; sIndex++)
              _buildSetRow(context, exIndex, sIndex, ex.sets[sIndex], cubit),

            const SizedBox(height: 8),
            // Кнопка додати підхід
            TextButton.icon(
              onPressed: () => cubit.addSet(exIndex),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Додати підхід'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(
    BuildContext context,
    int exIndex,
    int sIndex,
    dynamic workoutSet,
    ActiveWorkoutCubit cubit,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Номер сету
          SizedBox(
            width: 32,
            child: Text(
              '#${workoutSet.setNumber}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
          ),
          // Вага (кг)
          Expanded(
            flex: 3,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextFormField(
                initialValue: workoutSet.weight.toStringAsFixed(1).replaceAll('.0', ''),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val);
                  if (parsed != null) {
                    cubit.updateSet(exIndex, sIndex, weight: parsed);
                  }
                },
              ),
            ),
          ),
          // Повторення
          Expanded(
            flex: 3,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextFormField(
                initialValue: workoutSet.reps.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null) {
                    cubit.updateSet(exIndex, sIndex, reps: parsed);
                  }
                },
              ),
            ),
          ),
          // Тип підходу (Робочий чи Розминка)
          Expanded(
            flex: 3,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                final newCat = workoutSet.category == SetCategory.working
                    ? SetCategory.warmup
                    : SetCategory.working;
                cubit.updateSet(exIndex, sIndex, category: newCat);
              },
              child: Container(
                height: 38,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: workoutSet.category == SetCategory.warmup
                      ? Colors.orange.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: workoutSet.category == SetCategory.warmup
                        ? Colors.orange.shade300
                        : Colors.blue.shade300,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  workoutSet.category == SetCategory.warmup ? 'Розминка' : 'Робочий',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: workoutSet.category == SetCategory.warmup
                        ? Colors.orange.shade800
                        : Colors.blue.shade800,
                  ),
                ),
              ),
            ),
          ),
          // Чекбокс виконання
          SizedBox(
            width: 48,
            child: Checkbox(
              value: workoutSet.isCompleted,
              activeColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (val) {
                cubit.updateSet(exIndex, sIndex, isCompleted: val ?? false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimerBar(
    BuildContext context,
    ActiveWorkoutInProgress state,
    ActiveWorkoutCubit cubit,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            if (state.isTimerRunning) ...[
              Text(
                'Відпочинок: ${DateFormatter.formatSeconds(state.timerSecondsRemaining)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => cubit.startRestTimer(state.timerSecondsRemaining + 30),
                child: const Text('+30с'),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => cubit.stopRestTimer(),
              ),
            ] else ...[
              const Text('Відпочинок:', style: TextStyle(fontSize: 13, color: Colors.black54)),
              const Spacer(),
              _timerChip('60с', 60, cubit),
              const SizedBox(width: 6),
              _timerChip('90с', 90, cubit),
              const SizedBox(width: 6),
              _timerChip('120с', 120, cubit),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timerChip(String label, int seconds, ActiveWorkoutCubit cubit) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: () => cubit.startRestTimer(seconds),
    );
  }

  void _showFinishDialog(BuildContext context, ActiveWorkoutCubit cubit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Завершити тренування?'),
        content: const Text('Усі виконані підходи будуть збережені у вашу базу даних.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Продовжити'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              cubit.saveWorkout();
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }

  String _equipmentLabel(String eq) {
    switch (eq) {
      case 'barbell':
        return 'Штанга';
      case 'dumbbells':
        return 'Гантелі';
      case 'machine':
        return 'Тренажер';
      case 'bodyweight':
        return 'Власна вага';
      default:
        return eq;
    }
  }
}
