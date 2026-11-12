import 'workout_enums.dart';

class WorkoutSet {
  final String? id;
  final int setNumber;
  final double weight; // Робоча вага (кг)
  final int reps; // Кількість повторень
  final SetCategory category; // Розминочний чи робочий
  final int? restTimeSeconds; // Час відпочинку між підходами (сек)
  final bool isCompleted; // Чи відмічений як виконаний

  const WorkoutSet({
    this.id,
    this.setNumber = 1,
    required this.weight,
    required this.reps,
    this.category = SetCategory.working,
    this.restTimeSeconds,
    this.isCompleted = false,
  });

  WorkoutSet copyWith({
    String? id,
    int? setNumber,
    double? weight,
    int? reps,
    SetCategory? category,
    int? restTimeSeconds,
    bool? isCompleted,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      category: category ?? this.category,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
