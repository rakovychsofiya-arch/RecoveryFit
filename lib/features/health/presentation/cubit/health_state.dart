import 'package:equatable/equatable.dart';
import '../../domain/entities/health_metric.dart';
import '../../domain/entities/sleep_session.dart';

abstract class HealthState extends Equatable {
  const HealthState();

  @override
  List<Object?> get props => [];
}

class HealthInitial extends HealthState {}

class HealthLoading extends HealthState {}

class HealthLoaded extends HealthState {
  final HealthMetric metric;
  final List<SleepSession> sleepSessions;

  const HealthLoaded({
    required this.metric,
    required this.sleepSessions,
  });

  @override
  List<Object?> get props => [metric, sleepSessions];
}

class HealthError extends HealthState {
  final String message;

  const HealthError(this.message);

  @override
  List<Object?> get props => [message];
}
