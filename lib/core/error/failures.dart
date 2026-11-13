import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Помилка бази даних']);
}

class HealthDataFailure extends Failure {
  const HealthDataFailure([super.message = 'Помилка отримання даних про здоров\'я']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
