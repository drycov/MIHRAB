import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../domain/reminders.dart';

class Notifications {
  final plugin = FlutterLocalNotificationsPlugin();
  bool initialized = false;
  bool get supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!supported || initialized) return;
    await plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
    ));
    initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (!supported) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission() ?? false;
    }
    return await plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: false, sound: true) ?? false;
  }

  Future<void> replace(List<PrayerReminder> reminders) async {
    await initialize();
    if (!supported) return;
    for (final item in await plugin.pendingNotificationRequests()) {
      if (item.id >= 1000 && item.id < 1120) await plugin.cancel(item.id);
    }
    for (final item in reminders) {
      await plugin.zonedSchedule(
        item.id, item.kind.label,
        item.minutesBefore == 0 ? 'Наступило время намаза' : 'До намаза ${item.minutesBefore} мин.',
        item.time,
        const NotificationDetails(
          android: AndroidNotificationDetails('prayer_reminders', 'Время намаза', importance: Importance.high, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
