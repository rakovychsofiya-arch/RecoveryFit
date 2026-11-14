import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/health_metric.dart';
import '../../domain/usecases/get_daily_health_usecase.dart';
import '../../domain/usecases/get_sleep_sessions_usecase.dart';
import 'health_state.dart';

class HealthCubit extends Cubit<HealthState> {
  final GetDailyHealthUseCase getDailyHealthUseCase;
  final GetSleepSessionsUseCase getSleepSessionsUseCase;

  HealthCubit({
    required this.getDailyHealthUseCase,
    required this.getSleepSessionsUseCase,
  }) : super(HealthInitial());

  Future<void> fetchTodayHealth() async {
    emit(HealthLoading());
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final sleepWindowStart = startOfDay.subtract(const Duration(hours: 14));

      final metric = await getDailyHealthUseCase(now) ??
          HealthMetric(date: now, stepsCount: 0, activeCalories: 0);

      final sleepSessions = await getSleepSessionsUseCase(
        startDate: sleepWindowStart,
        endDate: now,
      );

      emit(HealthLoaded(metric: metric, sleepSessions: sleepSessions));
    } catch (e) {
      emit(HealthError('Не вдалося завантажити дані: $e'));
    }
  }
}
