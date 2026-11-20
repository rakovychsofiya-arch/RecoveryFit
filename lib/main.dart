import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/database/database_helper.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/health/data/datasources/health_remote_data_source.dart';
import 'features/health/data/repositories/health_repository_impl.dart';
import 'features/health/domain/usecases/get_daily_health_usecase.dart';
import 'features/health/domain/usecases/get_sleep_sessions_usecase.dart';
import 'features/health/presentation/cubit/health_cubit.dart';
import 'features/navigation/main_navigation_screen.dart';
import 'features/workouts/data/datasource/workout_local_data_source.dart';
import 'features/workouts/data/repositories/workout_repository_impl.dart';
import 'features/workouts/domain/usecases/delete_workout_usecase.dart';
import 'features/workouts/domain/usecases/get_exercises_usecase.dart';
import 'features/workouts/domain/usecases/get_templates_usecase.dart';
import 'features/workouts/domain/usecases/get_workout_usecase.dart';
import 'features/workouts/domain/usecases/save_template_usecase.dart';
import 'features/workouts/domain/usecases/save_workout_usecase.dart';
import 'features/workouts/presentation/cubit/active_workout_cubit.dart';
import 'features/workouts/presentation/cubit/workout_history_cubit.dart';
import 'features/workouts/presentation/cubit/workout_templates_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Ініціалізація бази даних SQLite
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database; // Тригерить створення таблиць та початковий seed вправ

  // 2. Ініціалізація локальних сповіщень (для таймера та годинника)
  await NotificationService.instance.init();

  // 3. Data Sources
  final workoutLocalDataSource = WorkoutLocalDataSourceImpl(dbHelper: dbHelper);
  final healthRemoteDataSource = HealthRemoteDataSourceImpl();

  // 3. Repositories
  final workoutRepository = WorkoutRepositoryImpl(localDataSource: workoutLocalDataSource);
  final healthRepository = HealthRepositoryImpl(remoteDataSource: healthRemoteDataSource);

  // 4. Use Cases
  final getExercisesUseCase = GetExercisesUseCase(workoutRepository);
  final getTemplatesUseCase = GetTemplatesUseCase(workoutRepository);
  final saveTemplateUseCase = SaveTemplateUseCase(workoutRepository);
  final getWorkoutsUseCase = GetWorkoutsUseCase(workoutRepository);
  final saveWorkoutUseCase = SaveWorkoutUseCase(workoutRepository);
  final deleteWorkoutUseCase = DeleteWorkoutUseCase(workoutRepository);

  final getDailyHealthUseCase = GetDailyHealthUseCase(healthRepository);
  final getSleepSessionsUseCase = GetSleepSessionsUseCase(healthRepository);

  runApp(FitnessApp(
    getExercisesUseCase: getExercisesUseCase,
    getTemplatesUseCase: getTemplatesUseCase,
    saveTemplateUseCase: saveTemplateUseCase,
    getWorkoutsUseCase: getWorkoutsUseCase,
    saveWorkoutUseCase: saveWorkoutUseCase,
    deleteWorkoutUseCase: deleteWorkoutUseCase,
    getDailyHealthUseCase: getDailyHealthUseCase,
    getSleepSessionsUseCase: getSleepSessionsUseCase,
    workoutRepository: workoutRepository,
  ));
}

class FitnessApp extends StatelessWidget {
  final GetExercisesUseCase getExercisesUseCase;
  final GetTemplatesUseCase getTemplatesUseCase;
  final SaveTemplateUseCase saveTemplateUseCase;
  final GetWorkoutsUseCase getWorkoutsUseCase;
  final SaveWorkoutUseCase saveWorkoutUseCase;
  final DeleteWorkoutUseCase deleteWorkoutUseCase;
  final GetDailyHealthUseCase getDailyHealthUseCase;
  final GetSleepSessionsUseCase getSleepSessionsUseCase;
  final WorkoutRepositoryImpl workoutRepository;

  const FitnessApp({
    super.key,
    required this.getExercisesUseCase,
    required this.getTemplatesUseCase,
    required this.saveTemplateUseCase,
    required this.getWorkoutsUseCase,
    required this.saveWorkoutUseCase,
    required this.deleteWorkoutUseCase,
    required this.getDailyHealthUseCase,
    required this.getSleepSessionsUseCase,
    required this.workoutRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => HealthCubit(
            getDailyHealthUseCase: getDailyHealthUseCase,
            getSleepSessionsUseCase: getSleepSessionsUseCase,
          )..fetchTodayHealth(),
        ),
        BlocProvider(
          create: (_) => WorkoutTemplatesCubit(
            getTemplatesUseCase: getTemplatesUseCase,
            saveTemplateUseCase: saveTemplateUseCase,
            repository: workoutRepository,
          )..loadTemplates(),
        ),
        BlocProvider(
          create: (_) => WorkoutHistoryCubit(
            getWorkoutsUseCase: getWorkoutsUseCase,
            deleteWorkoutUseCase: deleteWorkoutUseCase,
            saveWorkoutUseCase: saveWorkoutUseCase,
          )..loadHistory(),
        ),
        BlocProvider(
          create: (_) => ActiveWorkoutCubit(
            saveWorkoutUseCase: saveWorkoutUseCase,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Fitness & Health App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: MainNavigationScreen(getExercisesUseCase: getExercisesUseCase),
      ),
    );
  }
}
