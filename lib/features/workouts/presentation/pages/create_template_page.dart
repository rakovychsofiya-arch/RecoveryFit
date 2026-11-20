import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/usecases/get_exercises_usecase.dart';
import '../cubit/workout_templates_cubit.dart';
import '../widgets/exercise_picker_dialog.dart';

class CreateTemplatePage extends StatefulWidget {
  final GetExercisesUseCase getExercisesUseCase;

  const CreateTemplatePage({super.key, required this.getExercisesUseCase});

  @override
  State<CreateTemplatePage> createState() => _CreateTemplatePageState();
}

class _CreateTemplatePageState extends State<CreateTemplatePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<TemplateExercise> _exercises = [];
  final Uuid _uuid = const Uuid();

  void _addExercise(Exercise ex) {
    setState(() {
      _exercises.add(TemplateExercise(
        id: _uuid.v4(),
        exerciseName: ex.name,
        equipment: ex.equipment,
        orderIndex: _exercises.length,
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 20.0,
      ));
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть назву програми (наприклад: "День ніг")')),
      );
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Додайте хоча б одну вправу до плану')),
      );
      return;
    }

    final template = WorkoutTemplate(
      id: _uuid.v4(),
      title: title,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      exercises: _exercises,
      createdAt: DateTime.now(),
    );

    context.read<WorkoutTemplatesCubit>().saveTemplate(template);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Нова програма тренувань'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Зберегти програму',
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Назва програми',
              hintText: 'наприклад: День ніг або Тренування понеділка',
              prefixIcon: Icon(Icons.fitness_center),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Нотатки (опційно)',
              hintText: 'наприклад: Відпочинок 90 сек, фокус на квадрицепси',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Вправи в плані (${_exercises.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () async {
                  final ex = await showModalBottomSheet<Exercise>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ExercisePickerDialog(getExercisesUseCase: widget.getExercisesUseCase),
                  );
                  if (ex != null) {
                    _addExercise(ex);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Додати вправу'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_exercises.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'Список вправ порожній.\nНатисніть "+ Додати вправу", щоб обрати вправи з каталогу.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            )
          else
            for (int i = 0; i < _exercises.length; i++)
              _buildExerciseCard(i),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(int index) {
    final tEx = _exercises[index];
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
                    '${index + 1}. ${tEx.exerciseName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      _exercises.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Підходів', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: tEx.defaultSets.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null) {
                            _exercises[index] = tEx.copyWith(defaultSets: parsed);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Повторень', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: tEx.defaultReps.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null) {
                            _exercises[index] = tEx.copyWith(defaultReps: parsed);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Вага (кг)', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: tEx.defaultWeight.toStringAsFixed(1).replaceAll('.0', ''),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) {
                            _exercises[index] = tEx.copyWith(defaultWeight: parsed);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
