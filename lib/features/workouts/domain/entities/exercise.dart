import 'workout_enums.dart';

class Exercise {
  final String id;
  final String name;
  final String category;
  final EquipmentType equipment;
  final String? description;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.equipment,
    this.description,
  });
}
