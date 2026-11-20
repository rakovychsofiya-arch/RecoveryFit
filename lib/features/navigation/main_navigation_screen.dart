import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../health/presentation/pages/health_page.dart';
import '../workouts/domain/usecases/get_exercises_usecase.dart';
import '../workouts/presentation/pages/workout_history_page.dart';
import '../workouts/presentation/pages/workouts_dashboard_page.dart';

class MainNavigationScreen extends StatefulWidget {
  final GetExercisesUseCase getExercisesUseCase;

  const MainNavigationScreen({
    super.key,
    required this.getExercisesUseCase,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      WorkoutsDashboardPage(getExercisesUseCase: widget.getExercisesUseCase),
      const HealthPage(),
      const WorkoutHistoryPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: AppTheme.primaryLight.withAlpha(50),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center, color: AppTheme.primaryColor),
            label: 'Тренування',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety, color: AppTheme.primaryColor),
            label: 'Здоров\'я',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppTheme.primaryColor),
            label: 'Історія',
          ),
        ],
      ),
    );
  }
}
