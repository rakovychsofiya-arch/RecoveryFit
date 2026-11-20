import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/usecases/get_exercises_usecase.dart';
import '../cubit/active_workout_cubit.dart';
import '../cubit/workout_history_cubit.dart';
import '../cubit/workout_templates_cubit.dart';
import '../cubit/workout_templates_state.dart';
import 'active_strength_workout_page.dart';
import 'create_template_page.dart';

class WorkoutsDashboardPage extends StatefulWidget {
  final GetExercisesUseCase getExercisesUseCase;

  const WorkoutsDashboardPage({super.key, required this.getExercisesUseCase});

  @override
  State<WorkoutsDashboardPage> createState() => _WorkoutsDashboardPageState();
}

class _WorkoutsDashboardPageState extends State<WorkoutsDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<WorkoutTemplatesCubit>().loadTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренування'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Секція швидкого старту
          const Text(
            'Швидкий старт',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickStartButton(
                  title: 'Силове',
                  icon: Icons.fitness_center,
                  color: AppTheme.primaryColor,
                  onTap: () {
                    context.read<ActiveWorkoutCubit>().startStrengthWorkout(title: 'Вільне тренування');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActiveStrengthWorkoutPage(getExercisesUseCase: widget.getExercisesUseCase),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStartButton(
                  title: 'Кардіо',
                  icon: Icons.directions_run,
                  color: Colors.orange.shade700,
                  onTap: () => _showCardioDialog(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStartButton(
                  title: 'Розтяжка',
                  icon: Icons.self_improvement,
                  color: Colors.teal.shade700,
                  onTap: () => _showStretchingDialog(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2. Секція програм (шаблонів)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Мої програми',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateTemplatePage(getExercisesUseCase: widget.getExercisesUseCase),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('+ Створити'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          BlocBuilder<WorkoutTemplatesCubit, WorkoutTemplatesState>(
            builder: (context, state) {
              if (state is WorkoutTemplatesLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (state is WorkoutTemplatesLoaded) {
                if (state.templates.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Немає створених програм',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Створіть свій спліт (наприклад: "День ніг" або "Груди/Спина") для швидкого старту тренування.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateTemplatePage(getExercisesUseCase: widget.getExercisesUseCase),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Створити першу програму'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: state.templates.map((t) => _buildTemplateCard(context, t)).toList(),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 20,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, WorkoutTemplate template) {
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
                Expanded(
                  child: Text(
                    template.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    context.read<WorkoutTemplatesCubit>().deleteTemplate(template.id);
                  },
                ),
              ],
            ),
            if (template.notes != null && template.notes!.isNotEmpty) ...[
              Text(
                template.notes!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Вправ у плані: ${template.exercises.length}',
              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: template.exercises.map((e) {
                return Chip(
                  label: Text(e.exerciseName, style: const TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.grey.shade100,
                );
              }).toList(),
            ),
            const Divider(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<ActiveWorkoutCubit>().startStrengthWorkout(template: template);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActiveStrengthWorkoutPage(getExercisesUseCase: widget.getExercisesUseCase),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Розпочати це тренування'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardioDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: 'Пробіжка / Кардіо');
    final distCtrl = TextEditingController(text: '3.5');
    final durCtrl = TextEditingController(text: '25');
    final hrCtrl = TextEditingController(text: '145');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Запис кардіо тренування'),
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
            onPressed: () async {
              final cubit = context.read<ActiveWorkoutCubit>();
              cubit.startCardioWorkout(
                title: titleCtrl.text.trim(),
                distanceInKm: double.tryParse(distCtrl.text) ?? 0.0,
                durationMinutes: int.tryParse(durCtrl.text) ?? 0,
                avgHeartRate: int.tryParse(hrCtrl.text),
              );
              await cubit.saveWorkout();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                context.read<WorkoutHistoryCubit>().loadHistory();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Кардіо тренування збережено!'), backgroundColor: AppTheme.primaryColor),
                );
              }
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }

  void _showStretchingDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: 'Розтяжка після тренування');
    final targetCtrl = TextEditingController(text: 'Ноги та спина');
    final durCtrl = TextEditingController(text: '15');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Запис розтяжки'),
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
            onPressed: () async {
              final cubit = context.read<ActiveWorkoutCubit>();
              cubit.startStretchingWorkout(
                title: titleCtrl.text.trim(),
                durationMinutes: int.tryParse(durCtrl.text) ?? 0,
                targetMuscleGroup: targetCtrl.text.trim(),
              );
              await cubit.saveWorkout();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                context.read<WorkoutHistoryCubit>().loadHistory();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Розтяжку збережено!'), backgroundColor: AppTheme.primaryColor),
                );
              }
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }
}
