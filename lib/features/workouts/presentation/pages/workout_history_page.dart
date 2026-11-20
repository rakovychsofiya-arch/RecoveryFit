import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/workout_enums.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/workout_session.dart';
import '../cubit/workout_history_cubit.dart';
import '../cubit/workout_history_state.dart';

class WorkoutHistoryPage extends StatelessWidget {
  const WorkoutHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Історія тренувань'),
      ),
      body: BlocBuilder<WorkoutHistoryCubit, WorkoutHistoryState>(
        builder: (context, state) {
          if (state is WorkoutHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WorkoutHistoryLoaded) {
            if (state.sessions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'Історія тренувань порожня',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Проведіть своє перше тренування у вкладці "Тренування", і воно з\'явиться тут.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<WorkoutHistoryCubit>().loadHistory(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.sessions.length,
                itemBuilder: (context, index) {
                  final session = state.sessions[index];
                  return _buildSessionCard(context, session);
                },
              ),
            );
          }

          if (state is WorkoutHistoryError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, WorkoutSession session) {
    Color typeColor;
    String typeLabel;
    IconData typeIcon;

    switch (session.type) {
      case WorkoutType.strength:
        typeColor = AppTheme.primaryColor;
        typeLabel = 'Силове';
        typeIcon = Icons.fitness_center;
        break;
      case WorkoutType.cardio:
        typeColor = Colors.orange.shade700;
        typeLabel = 'Кардіо';
        typeIcon = Icons.directions_run;
        break;
      case WorkoutType.stretching:
        typeColor = Colors.teal.shade700;
        typeLabel = 'Розтяжка';
        typeIcon = Icons.self_improvement;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showWorkoutDetailsModal(context, session),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: typeColor.withAlpha(38),
                        child: Icon(typeIcon, size: 20, color: typeColor),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            DateFormatter.formatDate(session.date),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              if (session is StrengthWorkoutSession) ...[
                Text(
                  'Вправ: ${session.exercises.length} • Загалом сетів: ${session.exercises.fold<int>(0, (sum, e) => sum + e.sets.length)}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                if (session.notes != null && session.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Нотатки: ${session.notes}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: session.exercises.map((e) {
                    return Chip(
                      label: Text(e.name, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.grey.shade100,
                    );
                  }).toList(),
                ),
              ] else if (session is CardioWorkoutSession) ...[
                Text(
                  'Дистанція: ${session.distanceInKm} км • Тривалість: ${session.durationMinutes} хв',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (session.avgHeartRate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Середній пульс: ${session.avgHeartRate} bpm',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ] else if (session is StretchingWorkoutSession) ...[
                Text(
                  'Зона м\'язів: ${session.targetMuscleGroup} • Тривалість: ${session.durationMinutes} хв',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Іконка Око: детальний огляд
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, color: AppTheme.primaryColor, size: 20),
                    tooltip: 'Детальний огляд (Око)',
                    onPressed: () {
                      _showWorkoutDetailsModal(context, session);
                    },
                  ),
                  // Іконка Олівець: редагування
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                    tooltip: 'Редагувати тренування',
                    onPressed: () {
                      _showEditDialog(context, session);
                    },
                  ),
                  // Іконка Смітник: видалення
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    tooltip: 'Видалити тренування',
                    onPressed: () {
                      _confirmDelete(context, session.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkoutDetailsModal(BuildContext context, WorkoutSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${DateFormatter.formatDate(session.date)} • ${DateFormatter.formatTime(session.date)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
            const Divider(height: 20),
            Expanded(
              child: ListView(
                children: [
                  if (session is StrengthWorkoutSession) ...[
                    _buildStrengthSummaryCard(session),
                    const SizedBox(height: 16),
                    const Text(
                      'Вправи та виконані підходи:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < session.exercises.length; i++)
                      _buildExerciseDetailCard(session.exercises[i], i + 1),
                  ] else if (session is CardioWorkoutSession) ...[
                    _buildCardioDetails(session),
                  ] else if (session is StretchingWorkoutSession) ...[
                    _buildStretchingDetails(session),
                  ],
                  if (session.notes != null && session.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notes, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Загальні нотатки: ${session.notes}',
                                style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthSummaryCard(StrengthWorkoutSession session) {
    final totalExercises = session.exercises.length;
    final totalSets = session.exercises.fold<int>(0, (sum, e) => sum + e.sets.length);

    return Card(
      color: AppTheme.primaryColor.withAlpha(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  '$totalExercises',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 4),
                const Text('Вправ виконано', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            Container(width: 1, height: 36, color: Colors.grey.shade300),
            Column(
              children: [
                Text(
                  '$totalSets',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 4),
                const Text('Всього підходів', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetailCard(WorkoutExercise ex, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$index. ${ex.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _equipmentLabel(ex.equipment.name),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
            if (ex.notes != null && ex.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment_outlined, size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Нотатка: "${ex.notes}"',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 16),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(36),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: FlexColumnWidth(),
              },
              children: [
                const TableRow(
                  children: [
                    Text('Сет', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
                    Text('Вага', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
                    Text('Повтор.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
                    Text('Тип', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
                  ],
                ),
                for (var st in ex.sets)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('#${st.setNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          ex.equipment == EquipmentType.bodyweight
                              ? 'Власна'
                              : '${st.weight.toStringAsFixed(1).replaceAll('.0', '')} кг',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${st.reps}', style: const TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          st.category == SetCategory.warmup ? 'Розминка' : 'Робочий',
                          style: TextStyle(
                            fontSize: 11,
                            color: st.category == SetCategory.warmup ? Colors.orange.shade800 : Colors.black87,
                            fontWeight: st.category == SetCategory.warmup ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardioDetails(CardioWorkoutSession session) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.directions_run, color: Colors.deepOrange),
                SizedBox(width: 8),
                Text('Параметри кардіо', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricItem('${session.distanceInKm} км', 'Дистанція'),
                _metricItem('${session.durationMinutes} хв', 'Час'),
                if (session.avgHeartRate != null)
                  _metricItem('${session.avgHeartRate} bpm', 'Пульс'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStretchingDetails(StretchingWorkoutSession session) {
    return Card(
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.self_improvement, color: Colors.teal),
                SizedBox(width: 8),
                Text('Параметри розтяжки', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricItem(session.targetMuscleGroup, 'Цільова група'),
                _metricItem('${session.durationMinutes} хв', 'Час'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  void _showEditDialog(BuildContext context, WorkoutSession session) {
    final titleCtrl = TextEditingController(text: session.title);

    if (session is CardioWorkoutSession) {
      final distCtrl = TextEditingController(text: session.distanceInKm.toString());
      final durCtrl = TextEditingController(text: session.durationMinutes.toString());
      final hrCtrl = TextEditingController(text: session.avgHeartRate?.toString() ?? '');

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Редагувати кардіо'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Назва')),
                const SizedBox(height: 8),
                TextField(controller: distCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Дистанція (км)')),
                const SizedBox(height: 8),
                TextField(controller: durCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Час (хвилин)')),
                const SizedBox(height: 8),
                TextField(controller: hrCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Середній пульс (bpm, опційно)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
            ElevatedButton(
              onPressed: () {
                final updated = session.copyWith(
                  title: titleCtrl.text.trim(),
                  distanceInKm: double.tryParse(distCtrl.text) ?? session.distanceInKm,
                  durationMinutes: int.tryParse(durCtrl.text) ?? session.durationMinutes,
                  avgHeartRate: int.tryParse(hrCtrl.text),
                );
                context.read<WorkoutHistoryCubit>().updateWorkout(updated);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Кардіо тренування оновлено!'), backgroundColor: AppTheme.primaryColor),
                );
              },
              child: const Text('Зберегти зміни'),
            ),
          ],
        ),
      );
    } else if (session is StretchingWorkoutSession) {
      final targetCtrl = TextEditingController(text: session.targetMuscleGroup);
      final durCtrl = TextEditingController(text: session.durationMinutes.toString());

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Редагувати розтяжку'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Назва')),
                const SizedBox(height: 8),
                TextField(controller: targetCtrl, decoration: const InputDecoration(labelText: 'Цільова група м\'язів')),
                const SizedBox(height: 8),
                TextField(controller: durCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Час (хвилин)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
            ElevatedButton(
              onPressed: () {
                final updated = session.copyWith(
                  title: titleCtrl.text.trim(),
                  targetMuscleGroup: targetCtrl.text.trim(),
                  durationMinutes: int.tryParse(durCtrl.text) ?? session.durationMinutes,
                );
                context.read<WorkoutHistoryCubit>().updateWorkout(updated);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Розтяжку оновлено!'), backgroundColor: AppTheme.primaryColor),
                );
              },
              child: const Text('Зберегти зміни'),
            ),
          ],
        ),
      );
    } else if (session is StrengthWorkoutSession) {
      final notesCtrl = TextEditingController(text: session.notes ?? '');

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Редагувати силове тренування'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Назва')),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Нотатки')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
            ElevatedButton(
              onPressed: () {
                final updated = session.copyWith(
                  title: titleCtrl.text.trim(),
                  notes: notesCtrl.text.trim(),
                );
                context.read<WorkoutHistoryCubit>().updateWorkout(updated);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Силове тренування оновлено!'), backgroundColor: AppTheme.primaryColor),
                );
              },
              child: const Text('Зберегти зміни'),
            ),
          ],
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити запис?'),
        content: const Text('Це тренування буде назавжди видалено з історії.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<WorkoutHistoryCubit>().deleteWorkout(id);
            },
            child: const Text('Видалити'),
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
