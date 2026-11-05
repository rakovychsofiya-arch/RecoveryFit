// features/health/domain/entities/sleep_session.dart
class SleepSession {
  final DateTime startTime;
  final DateTime endTime;
  final Duration totalDuration;
  final Duration deepSleep;
  final Duration remSleep;

  const SleepSession({
    required this.startTime,
    required this.endTime,
    required this.totalDuration,
    required this.deepSleep,
    required this.remSleep,
  });
}