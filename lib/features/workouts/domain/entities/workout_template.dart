import 'workout_enums.dart';

class TemplateExercise {
  final String id;
  final String exerciseName;
  final EquipmentType equipment;
  final int orderIndex;
  final int defaultSets;
  final int defaultReps;
  final double defaultWeight;

  const TemplateExercise({
    required this.id,
    required this.exerciseName,
    required this.equipment,
    required this.orderIndex,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.defaultWeight = 20.0,
  });

  TemplateExercise copyWith({
    String? id,
    String? exerciseName,
    EquipmentType? equipment,
    int? orderIndex,
    int? defaultSets,
    int? defaultReps,
    double? defaultWeight,
  }) {
    return TemplateExercise(
      id: id ?? this.id,
      exerciseName: exerciseName ?? this.exerciseName,
      equipment: equipment ?? this.equipment,
      orderIndex: orderIndex ?? this.orderIndex,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultWeight: defaultWeight ?? this.defaultWeight,
    );
  }
}

class WorkoutTemplate {
  final String id;
  final String title; // наприклад: "День ніг" або "Тренування понеділка"
  final String? notes;
  final List<TemplateExercise> exercises;
  final DateTime createdAt;

  const WorkoutTemplate({
    required this.id,
    required this.title,
    this.notes,
    required this.exercises,
    required this.createdAt,
  });

  WorkoutTemplate copyWith({
    String? id,
    String? title,
    String? notes,
    List<TemplateExercise>? exercises,
    DateTime? createdAt,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
