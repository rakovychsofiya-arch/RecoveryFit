import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(initSettings);

      // Запит дозволу для Android 13+
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Помилка ініціалізації сповіщень: $e');
    }
  }

  Future<void> showRestTimerFinishedNotification() async {
    // 1. Тактильний відгук (вібрація телефону)
    try {
      await HapticFeedback.heavyImpact();
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    // 2. Системний push на телефон (який також дублюється на смарт-годинник)
    const androidDetails = AndroidNotificationDetails(
      'rest_timer_channel',
      'Таймер відпочинку',
      channelDescription: 'Сповіщення про завершення часу відпочинку між підходами',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        1001,
        'Час відпочинку вичерпано! ⏱️',
        'Пора повертатися до наступного підходу!',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Не вдалося показати сповіщення: $e');
    }
  }
}
