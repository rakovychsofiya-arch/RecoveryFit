import 'package:equatable/equatable.dart';
import '../../domain/entities/workout_session.dart';

abstract class ActiveWorkoutState extends Equatable {
  const ActiveWorkoutState();

  @override
  List<Object?> get props => [];
}

class ActiveWorkoutInitial extends ActiveWorkoutState {}

class ActiveWorkoutInProgress extends ActiveWorkoutState {
  final WorkoutSession session;
  final int timerSecondsRemaining;
  final bool isTimerRunning;

  const ActiveWorkoutInProgress({
    required this.session,
    this.timerSecondsRemaining = 0,
    this.isTimerRunning = false,
  });

  ActiveWorkoutInProgress copyWith({
    WorkoutSession? session,
    int? timerSecondsRemaining,
    bool? isTimerRunning,
  }) {
    return ActiveWorkoutInProgress(
      session: session ?? this.session,
      timerSecondsRemaining: timerSecondsRemaining ?? this.timerSecondsRemaining,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
    );
  }

  @override
  List<Object?> get props => [session, timerSecondsRemaining, isTimerRunning];
}

class ActiveWorkoutSaved extends ActiveWorkoutState {}

class ActiveWorkoutError extends ActiveWorkoutState {
  final String message;

  const ActiveWorkoutError(this.message);

  @override
  List<Object?> get props => [message];
}
