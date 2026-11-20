import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_enums.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_set.dart';
import '../../domain/usecases/get_exercises_usecase.dart';
import '../cubit/active_workout_cubit.dart';
import '../cubit/active_workout_state.dart';
import '../cubit/workout_history_cubit.dart';
import '../cubit/workout_history_state.dart';
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

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _showExitConfirmationDialog(context);
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Вийти з тренування',
                onPressed: () => _showExitConfirmationDialog(context),
              ),
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
    final bool isBodyweight = ex.equipment == EquipmentType.bodyweight;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок вправи та вибір обладнання
            Row(
              children: [
                Expanded(
                  child: Text(
                    ex.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                // Око: перегляд минулих ваг та історії цієї вправи
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 20, color: AppTheme.primaryColor),
                  tooltip: 'Минулі ваги цієї вправи',
                  onPressed: () => _showPastExercisePerformance(context, ex.name),
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
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  tooltip: 'Видалити вправу',
                  onPressed: () {
                    cubit.removeExercise(exIndex);
                  },
                ),
              ],
            ),
            // Поле нотатки до вправи (опційно: як пройшла вправа, важко/легко)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
              child: TextFormField(
                initialValue: ex.notes ?? '',
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  hintText: 'Нотатка до вправи (наприклад: було важко на 3 сеті)...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.edit_note, size: 18, color: AppTheme.primaryColor),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: (val) => cubit.updateExerciseNotes(exIndex, val),
              ),
            ),
            const Divider(height: 14),

            // Заголовки колонок таблиці підходів
            Row(
              children: [
                const SizedBox(width: 28, child: Text('Сет', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      isBodyweight ? 'Вага' : 'Вага (кг)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                const Expanded(flex: 3, child: Center(child: Text('Повтор.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                const Expanded(flex: 3, child: Center(child: Text('Тип', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                const SizedBox(width: 82, child: Center(child: Text('Таймер', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
              ],
            ),
            const SizedBox(height: 8),

            // Рядки підходів
            for (int sIndex = 0; sIndex < ex.sets.length; sIndex++)
              _buildSetRow(context, ex, exIndex, sIndex, ex.sets[sIndex], cubit),

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
    WorkoutExercise ex,
    int exIndex,
    int sIndex,
    WorkoutSet workoutSet,
    ActiveWorkoutCubit cubit,
  ) {
    final bool isBodyweight = ex.equipment == EquipmentType.bodyweight;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: workoutSet.isCompleted ? const Color(0xFFF0FDF4) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Номер сету
          SizedBox(
            width: 28,
            child: Text(
              '#${workoutSet.setNumber}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
          ),
          // Вага (кг) або "Власна вага"
          Expanded(
            flex: 3,
            child: isBodyweight
                ? Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'Власна',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  )
                : Container(
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
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: workoutSet.category == SetCategory.warmup
                        ? Colors.orange.shade800
                        : Colors.blue.shade800,
                  ),
                ),
              ),
            ),
          ),
          // Кнопка Статусу (Відпочинок / Готово)
          SizedBox(
            width: 82,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                cubit.updateSet(exIndex, sIndex, isCompleted: !workoutSet.isCompleted);
              },
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: workoutSet.isCompleted ? AppTheme.primaryColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: workoutSet.isCompleted ? AppTheme.primaryColor : Colors.grey.shade300,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      workoutSet.isCompleted ? Icons.check_circle : Icons.timer_outlined,
                      size: 15,
                      color: workoutSet.isCompleted ? Colors.white : Colors.black87,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      workoutSet.isCompleted ? 'Готово' : 'Відпочити',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: workoutSet.isCompleted ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
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

  void _showPastExercisePerformance(BuildContext context, String exerciseName) {
    final historyState = context.read<WorkoutHistoryCubit>().state;
    final List<Map<String, dynamic>> pastLogs = [];

    if (historyState is WorkoutHistoryLoaded) {
      for (var session in historyState.sessions) {
        if (session is StrengthWorkoutSession) {
          for (var exercise in session.exercises) {
            if (exercise.name.toLowerCase() == exerciseName.toLowerCase()) {
              pastLogs.add({
                'date': session.date,
                'sessionTitle': session.title,
                'equipment': exercise.equipment,
                'notes': exercise.notes,
                'sets': exercise.sets,
              });
            }
          }
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.65,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exerciseName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Text(
              'Історія попередніх тренувань та робочих ваг',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const Divider(height: 20),
            Expanded(
              child: pastLogs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Попередніх записів не знайдено',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Це ваше перше тренування з цією вправою. Завершіть його, і робочі ваги збережуться!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: pastLogs.length,
                      itemBuilder: (context, idx) {
                        final log = pastLogs[idx];
                        final date = log['date'] as DateTime;
                        final sets = log['sets'] as List<WorkoutSet>;
                        final notes = log['notes'] as String?;
                        final eq = log['equipment'] as EquipmentType;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: Colors.grey.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormatter.formatDate(date),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                    ),
                                    Text(
                                      _equipmentLabel(eq.name),
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                if (notes != null && notes.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '💬 "$notes"',
                                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blueGrey.shade700),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: sets.map((st) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        eq == EquipmentType.bodyweight
                                            ? '#${st.setNumber}: ${st.reps} повт.'
                                            : '#${st.setNumber}: ${st.weight.toStringAsFixed(1).replaceAll('.0', '')} кг × ${st.reps}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
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

  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Перервати тренування?'),
        content: const Text('Усі поточні виконані підходи не будуть збережені. Ви дійсно бажаєте вийти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Продовжити тренування'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx); // Закрити діалог
              Navigator.pop(context); // Вийти з екрану тренування
            },
            child: const Text('Вийти без збереження'),
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
