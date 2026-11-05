import 'package:flutter/material.dart';
import 'package:health/health.dart';

void main() {
  runApp(const MaterialApp(
    home: HealthAppPage(),
  ));
}

class HealthAppPage extends StatefulWidget {
  const HealthAppPage({super.key});

  @override
  State<HealthAppPage> createState() => _HealthAppPageState();
}

class _HealthAppPageState extends State<HealthAppPage> {
  String _log = "Натисніть кнопку, щоб зчитати дані за сьогодні";
  bool _loading = false;

  final Health _health = Health();

  final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
  ];

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return "${hours} год ${minutes} хв";
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<void> _fetchDailyHealthData() async {
    setState(() {
      _loading = true;
      _log = "Зчитування даних за сьогодні...";
    });

    try {
      await _health.configure();

      final permissions = _types.map((e) => HealthDataAccess.READ).toList();
      try {
        await _health.requestAuthorization(_types, permissions: permissions);
      } catch (authError) {
        debugPrint("Запит дозволу пропущено або оброблено: $authError");
      }

      final now = DateTime.now();
      // Початок поточної доби для підрахунку кроків
      final startOfDay = DateTime(now.year, now.month, now.day);
      // Для сну беремо початок із вчорашнього вечора (наприклад, 18:00), щоб захопити нічну сесію
      final sleepWindowStart = startOfDay.subtract(const Duration(hours: 6));

      // 1. Агреговані кроки за сьогодні (00:00 -> зараз)
      final int? totalSteps = await _health.getTotalStepsInInterval(startOfDay, now);

      // 2. Сирі дані для сну та аналізу джерел
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: sleepWindowStart,
        endTime: now,
      );

      Duration totalSleepDuration = Duration.zero;
      Duration deepSleepDuration = Duration.zero;
      Duration remSleepDuration = Duration.zero;
      Duration lightSleepDuration = Duration.zero;

      final List<String> sleepSessionsDetails = [];
      final Set<String> sources = {};
      final StringBuffer detailsLog = StringBuffer(); // Оголошено змінну

      debugPrint("========================================");
      debugPrint("   ДАНІ ПРО ЗДОРОВ'Я ЗА СЬОГОДНІ");
      debugPrint("   Агреговані кроки: $totalSteps");
      debugPrint("   Знайдено сирих точок: ${healthData.length}");
      debugPrint("========================================");

      for (var point in healthData) {
        final String source = point.sourceName;
        final String sourceId = point.sourceId;
        sources.add("$source ($sourceId)");

        final logLine = "[${point.type.name}] Джерело: $source ($sourceId) | Значення: ${point.value}";
        debugPrint(logLine);

        if (point.type == HealthDataType.SLEEP_SESSION) {
          // Враховуємо сесію, якщо вона завершилася вже сьогодні
          if (point.dateTo.isAfter(startOfDay)) {
            final sessionDuration = point.dateTo.difference(point.dateFrom);
            totalSleepDuration += sessionDuration;
            // Підраховуємо конкретні фази сну
            switch (point.type) {
              case HealthDataType.SLEEP_DEEP:
                 deepSleepDuration += duration;
                 break;
               HealthDataType.SLEEP_REM:
                 remSleepDuration += duration;
                 break;
              case HealthDataType.SLEEP_LIGHT:
                 lightSleepDuration += duration;
                 break;
              case HealthDataType.SLEEP_SESSION:
                if (point.dateTo.isAfter(startOfDay)) {
                  totalSleepDuration += duration;
                  }
                  final sessionInfo =
                   "• ${_formatDuration(sessionDuration)} (з ${_formatTime(point.dateFrom)} до ${_formatTime(point.dateTo)}) [Джерело: $source]";

            sleepSessionsDetails.add(sessionInfo);
            debugPrint("[Сон] $sessionInfo | ID: $sourceId");
            }
          }
          break;
          default:
          break;
        }

        if (detailsLog.length < 500) {
          detailsLog.writeln("• ${point.type.name}: $source");
        }
      }

      final sleepReport = sleepSessionsDetails.isNotEmpty
          ? sleepSessionsDetails.join("\n")
          : "Записів сну за минулу ніч не знайдено";

      final sourcesReport = sources.isNotEmpty
          ? sources.join("\n")
          : "Джерела не визначено";

      if (!mounted) return;

      setState(() {
        _loading = false;
        _log = "✅ Дані за сьогодні:\n\n"
            "🏃 Кроки (агреговано): ${totalSteps ?? 0}\n\n"
            "🛌 Загальний сон: ${_formatDuration(totalSleepDuration)}\n"
            "  • Глибокий сон: ${_formatDuration(deepSleepDuration)}\n"
            "  • Швидкий сон (REM): ${_formatDuration(remSleepDuration)}\n"
            "  • Легкий сон: ${_formatDuration(lightSleepDuration)}\n\n"
            "Сесії сну (${sleepSessionsDetails.length}):\n"
            "$sleepReport\n\n"
            "📱 Джерела даних:\n"
            "$sourcesReport";
      });
    } catch (e) {
      debugPrint("Помилка під час зчитування: $e");
      if (!mounted) return;
      setState(() {
        _loading = false;
        _log = "Помилка зчитування: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Data (Сьогодні)"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_loading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _fetchDailyHealthData,
                  icon: const Icon(Icons.today),
                  label: const Text("Отримати дані за сьогодні"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _log,
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}