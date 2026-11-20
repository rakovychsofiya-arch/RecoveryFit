import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/workout_enums.dart';
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
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                  tooltip: 'Редагувати тренування',
                  onPressed: () {
                    _showEditDialog(context, session);
                  },
                ),
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
}
