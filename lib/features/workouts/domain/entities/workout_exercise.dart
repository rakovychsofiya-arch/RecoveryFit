import 'workout_enums.dart';
import 'workout_set.dart';

class WorkoutExercise {
  final String id;
  final String name;                 // Наприклад: "Жим лежачи"
  final EquipmentType equipment;      // Гантелі / штанга / тощо
  final List<WorkoutSet> sets;       // Список виконаних/планованих підходів

  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.equipment,
    required this.sets,
  });
}