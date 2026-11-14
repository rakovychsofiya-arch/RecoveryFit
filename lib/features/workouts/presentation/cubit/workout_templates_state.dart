import 'package:equatable/equatable.dart';
import '../../domain/entities/workout_template.dart';

abstract class WorkoutTemplatesState extends Equatable {
  const WorkoutTemplatesState();

  @override
  List<Object?> get props => [];
}

class WorkoutTemplatesInitial extends WorkoutTemplatesState {}

class WorkoutTemplatesLoading extends WorkoutTemplatesState {}

class WorkoutTemplatesLoaded extends WorkoutTemplatesState {
  final List<WorkoutTemplate> templates;

  const WorkoutTemplatesLoaded(this.templates);

  @override
  List<Object?> get props => [templates];
}

class WorkoutTemplatesError extends WorkoutTemplatesState {
  final String message;

  const WorkoutTemplatesError(this.message);

  @override
  List<Object?> get props => [message];
}
