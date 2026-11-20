import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../cubit/health_cubit.dart';
import '../cubit/health_state.dart';

class HealthPage extends StatelessWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Показники здоров\'я'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Оновити дані',
            onPressed: () {
              context.read<HealthCubit>().fetchTodayHealth();
            },
          ),
        ],
      ),
      body: BlocBuilder<HealthCubit, HealthState>(
        builder: (context, state) {
          if (state is HealthInitial) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.health_and_safety, size: 72, color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Дані Health Connect ще не завантажено',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.read<HealthCubit>().fetchTodayHealth(),
                    icon: const Icon(Icons.sync),
                    label: const Text('Синхронізувати з хмарою'),
                  ),
                ],
              ),
            );
          }

          if (state is HealthLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Зчитування даних про кроки та сон...'),
                ],
              ),
            );
          }

          if (state is HealthError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<HealthCubit>().fetchTodayHealth(),
                      child: const Text('Спробувати знову'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is HealthLoaded) {
            final metric = state.metric;
            final sessions = state.sleepSessions;

            return RefreshIndicator(
              onRefresh: () => context.read<HealthCubit>().fetchTodayHealth(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Картка активності (Кроки)
                  _buildStepsCard(metric.stepsCount, metric.activeCalories),
                  const SizedBox(height: 16),

                  // 2. Картка сну
                  _buildSleepCard(sessions),
                  const SizedBox(height: 16),

                  // 3. Інформаційна підказка
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Дані надходять у реальному часі через Google Health Connect із вашого смарт-годинника або фітнес-браслета.',
                              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStepsCard(int steps, double calories) {
    const targetSteps = 10000;
    final progress = (steps / targetSteps).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.directions_walk, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Активність за сьогодні',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '${(progress * 100).toInt()}% норми',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '$steps',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text('Кроків', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                Container(width: 1, height: 36, color: Colors.grey.shade300),
                Column(
                  children: [
                    Text(
                      calories.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text('Активні ккал', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard(List sessions) {
    if (sessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bedtime, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text(
                    'Сон за минулу ніч',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Сесій сну не знайдено або дані ще синхронізуються.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final session = sessions.first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bedtime, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      'Сон за минулу ніч',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  DateFormatter.formatDuration(session.totalDuration),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'з ${DateFormatter.formatTime(session.startTime)} до ${DateFormatter.formatTime(session.endTime)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPhaseItem('Глибокий', session.deepSleep, Colors.blue.shade800),
                _buildPhaseItem('Швидкий (REM)', session.remSleep, Colors.purple),
                _buildPhaseItem('Легкий', session.lightSleep, Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseItem(String label, Duration duration, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 6),
        Text(
          DateFormatter.formatDuration(duration),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
