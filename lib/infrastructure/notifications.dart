import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../domain/reminders.dart';

class Notifications {
  final plugin = FlutterLocalNotificationsPlugin();
  bool initialized = false;
  bool get supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!supported || initialized) return;
    await plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
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

  bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<bool> canScheduleExact() async {
    if (!isAndroid) return false;
    return await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.canScheduleExactNotifications() ?? false;
  }

  Future<bool> requestExactPermission() async {
    await initialize();
    if (!isAndroid) return false;
    if (await canScheduleExact()) return true;
    await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
    return canScheduleExact();
  }

  Future<bool> replace(List<PrayerReminder> reminders, {bool preferExact = false}) async {
    await initialize();
    if (!supported) return false;
    var exact = preferExact && await canScheduleExact();
    for (final item in await plugin.pendingNotificationRequests()) {
      if (item.id >= 1000 && item.id < 1120) await plugin.cancel(item.id);
    }
    for (final item in reminders) {
      if (!item.time.isAfter(DateTime.now())) continue;
      Future<void> schedule(AndroidScheduleMode mode) => plugin.zonedSchedule(
        item.id, item.kind.label,
        item.minutesBefore == 0 ? 'Наступило время намаза' : 'До намаза ${item.minutesBefore} мин.',
        item.time,
        const NotificationDetails(
          android: AndroidNotificationDetails('prayer_reminders', 'Время намаза', importance: Importance.high, priority: Priority.high, icon: 'ic_notification'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: mode,
      );
      try {
        await schedule(exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle);
      } on PlatformException catch (error) {
        if (!exact || error.code != 'exact_alarms_not_permitted') rethrow;
        exact = false;
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      }
    }
    return exact;
  }
}
