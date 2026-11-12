import 'workout_enums.dart';
import 'workout_set.dart';

class WorkoutExercise {
  final String id;
  final String exerciseId; // ID вправи з каталогу
  final String name; // Наприклад: "Жим лежачи"
  final EquipmentType equipment; // Гантелі / штанга / тощо
  final List<WorkoutSet> sets; // Список виконаних/планованих підходів
  final String? notes;

  const WorkoutExercise({
    required this.id,
    this.exerciseId = '',
    required this.name,
    required this.equipment,
    required this.sets,
    this.notes,
  });

  WorkoutExercise copyWith({
    String? id,
    String? exerciseId,
    String? name,
    EquipmentType? equipment,
    List<WorkoutSet>? sets,
    String? notes,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      equipment: equipment ?? this.equipment,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }
}
