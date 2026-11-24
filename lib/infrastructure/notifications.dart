import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../domain/reminders.dart';
import '../domain/prayer_schedule.dart';
import '../domain/prayer_sound.dart';

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
  Future<bool?> androidNotificationsEnabled() async {
    if (!isAndroid) return null;
    await initialize();
    return plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled();
  }

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

  NotificationDetails details(PrayerKind kind, PrayerSound sound, {bool early = false}) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          PrayerSoundChannels.id(kind, sound, early: early),
          PrayerSoundChannels.label(kind, sound, early: early),
          importance: sound == PrayerSound.silent ? Importance.low : Importance.high,
          priority: sound == PrayerSound.silent ? Priority.low : Priority.high,
          icon: 'ic_notification', playSound: sound == PrayerSound.system,
          enableVibration: sound != PrayerSound.silent,
        ),
        iOS: DarwinNotificationDetails(presentSound: sound == PrayerSound.system),
      );

  Future<void> preview(PrayerKind kind, PrayerSound sound) async {
    if (!supported) throw StateError('Проверка доступна на Android и iOS');
    if (!await requestPermission()) throw StateError('Нет разрешения на уведомления');
    await plugin.show(900, 'MIHRAB · ${kind.label}', 'Проверка звукового профиля',
      details(kind, sound));
  }

  Future<bool> replace(List<PrayerReminder> reminders, {bool preferExact = false,
    Map<PrayerKind, PrayerSound> sounds = const {}}) async {
    await initialize();
    if (!supported) return false;
    var exact = preferExact && await canScheduleExact();
    final desiredIds = reminders.where((item) => item.time.isAfter(DateTime.now())).map((item) => item.id).toSet();
    final previous = await plugin.pendingNotificationRequests();
    for (final item in reminders) {
      if (!item.time.isAfter(DateTime.now())) continue;
      Future<void> schedule(AndroidScheduleMode mode) => plugin.zonedSchedule(
        item.id, item.kind.label,
        item.minutesBefore == 0 ? 'Наступило время намаза' : 'До намаза ${item.minutesBefore} мин.',
        item.time,
        details(item.kind, sounds[item.kind] ?? PrayerSound.system, early: item.minutesBefore > 0),
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
    for (final item in previous) {
      if (ReminderPlanner.ownsId(item.id) && !desiredIds.contains(item.id)) {
        await plugin.cancel(item.id);
      }
    }
    return exact;
  }
}
