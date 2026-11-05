import 'workout_enums.dart';

class WorkoutSet {
  final double weight;      // Робоча вага (кг)
  final int reps;           // Кількість повторень
  final SetCategory category; // Розминочний чи робочий
  final bool isCompleted;   // Чи відмічений як виконаний

  const WorkoutSet({
    required this.weight,
    required this.reps,
    this.category = SetCategory.working,
    this.isCompleted = false,
  });

  // Метод copyWith для зручної зміни стану (наприклад, коли користувач ставить галочку "виконано")
  WorkoutSet copyWith({
    double? weight,
    int? reps,
    SetCategory? category,
    bool? isCompleted,
  }) {
    return WorkoutSet(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}