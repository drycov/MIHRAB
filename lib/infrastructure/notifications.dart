import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/reminder_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../domain/reminders.dart';
import '../domain/prayer_schedule.dart';
import '../domain/prayer_sound.dart';
import 'adhan_storage.dart';
import 'web_bridge.dart';

class Notifications {
  final plugin = FlutterLocalNotificationsPlugin();
  bool initialized = false;

  bool get supported =>
      WebBridge.isWeb ||
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS));

  bool get isWeb => WebBridge.isWeb;

  Future<void> initialize() async {
    if (!supported || initialized) return;
    if (isWeb) {
      initialized = true;
      return;
    }
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (!supported) return false;
    if (isWeb) {
      final result = await WebBridge.requestNotifications();
      return result == 'granted';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: false, sound: true) ??
        false;
  }

  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool?> androidNotificationsEnabled() async {
    if (!isAndroid) return null;
    await initialize();
    return plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();
  }

  Future<bool> canScheduleExact() async {
    if (!isAndroid) return false;
    return await plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.canScheduleExactNotifications() ??
        false;
  }

  Future<bool> requestExactPermission() async {
    await initialize();
    if (!isAndroid) return false;
    if (await canScheduleExact()) return true;
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
    return canScheduleExact();
  }

  Future<ReminderStrings> _strings() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderStrings(
      resolveReminderLanguage(
        prefs.getString('app_locale_v1'),
        PlatformDispatcher.instance.locales,
      ),
    );
  }

  Future<NotificationDetails> details(
    PrayerKind kind,
    PrayerSound sound, {
    bool early = false,
  }) async {
    String? uri;
    if (sound == PrayerSound.adhan) {
      if (isAndroid && !early) {
        final profile = kind == PrayerKind.fajr ? 'fajr' : 'standard';
        final bytes = await loadAdhanBytes(profile, 15 * 1024 * 1024);
        if (bytes != null && bytes.isNotEmpty) {
          uri = 'content://kz.zeus.mihrab.adhan/$profile';
        }
      }
      if (uri == null) sound = PrayerSound.system;
    }
    return NotificationDetails(
      android: AndroidNotificationDetails(
        PrayerSoundChannels.id(kind, sound, early: early),
        PrayerSoundChannels.label(kind, sound, early: early),
        importance:
            sound == PrayerSound.silent ? Importance.low : Importance.high,
        priority: sound == PrayerSound.silent ? Priority.low : Priority.high,
        icon: 'ic_notification',
        playSound: sound == PrayerSound.system || uri != null,
        sound: uri == null ? null : UriAndroidNotificationSound(uri),
        enableVibration: sound != PrayerSound.silent,
      ),
      iOS: DarwinNotificationDetails(presentSound: sound == PrayerSound.system),
    );
  }

  Future<void> preview(PrayerKind kind, PrayerSound sound) async {
    if (!supported) {
      throw StateError('Проверка доступна на Android, iOS и в PWA (браузер)');
    }
    if (!await requestPermission()) {
      throw StateError('Нет разрешения на уведомления');
    }
    final strings = await _strings();
    if (isWeb) {
      final ok = await WebBridge.showNotification(
        title: 'MIHRAB · ${strings.prayer(kind)}',
        body: strings.preview,
        tag: 'preview-${kind.name}',
      );
      if (!ok) throw StateError('Браузер не показал уведомление');
      return;
    }
    await plugin.show(
      900,
      'MIHRAB · ${strings.prayer(kind)}',
      strings.preview,
      await details(kind, sound),
    );
  }

  Future<bool> replace(
    List<PrayerReminder> reminders, {
    bool preferExact = false,
    Map<PrayerKind, PrayerSound> sounds = const {},
  }) async {
    await initialize();
    if (!supported) return false;
    final strings = await _strings();

    if (isWeb) {
      final future = reminders.where((item) => item.time.isAfter(DateTime.now()));
      final items = <Map<String, Object?>>[
        for (final item in future)
          {
            'id': item.id,
            'title': strings.title(item),
            'body': strings.body(item),
            'atMs': item.time.millisecondsSinceEpoch,
          },
      ];
      if (items.isEmpty) {
        await WebBridge.clearReminders();
        return false;
      }
      await WebBridge.scheduleReminders(items);
      // Web cannot guarantee exact OS alarms while the tab is closed.
      return false;
    }

    var exact = preferExact && await canScheduleExact();
    // iOS limits pending local requests to 64. Keep the earliest across both modules.
    reminders = [...reminders]..sort((a, b) => a.time.compareTo(b.time));
    if (!isAndroid && reminders.length > 60) {
      reminders = reminders.take(60).toList();
    }
    final desiredIds =
        reminders
            .where((item) => item.time.isAfter(DateTime.now()))
            .map((item) => item.id)
            .toSet();
    final previous = await plugin.pendingNotificationRequests();
    var nativeIds = <int>{};
    if (isAndroid) {
      final rows = [
        for (final item in reminders)
          if (!item.ramadan &&
              exact &&
              item.minutesBefore == 0 &&
              sounds[item.kind] == PrayerSound.adhan &&
              item.time.isAfter(DateTime.now()))
            {
              'id': item.id,
              'time': item.time.millisecondsSinceEpoch,
              'profile': item.kind == PrayerKind.fajr ? 'fajr' : 'standard',
            },
      ];
      for (final row in rows) {
        await plugin.cancel(row['id'] as int);
      }
      final ids = await const MethodChannel(
        'mihrab/adhan_scheduler',
      ).invokeListMethod<int>('replace', jsonEncode(rows));
      nativeIds = (ids ?? []).toSet();
    }

    for (final item in reminders) {
      if (!item.time.isAfter(DateTime.now())) continue;
      final notification =
          item.ramadan
              ? NotificationDetails(
                android: AndroidNotificationDetails(
                  'mihrab_ramadan_${item.kind.name}_v1',
                  item.kind == PrayerKind.fajr ? strings.suhoor : strings.iftar,
                  importance: Importance.high,
                  priority: Priority.high,
                  icon: 'ic_notification',
                ),
                iOS: const DarwinNotificationDetails(),
              )
              : await details(
                item.kind,
                nativeIds.contains(item.id)
                    ? PrayerSound.silent
                    : (sounds[item.kind] == PrayerSound.adhan
                        ? PrayerSound.system
                        : (sounds[item.kind] ?? PrayerSound.system)),
                early: item.minutesBefore > 0,
              );
      Future<void> schedule(AndroidScheduleMode mode) => plugin.zonedSchedule(
        item.id,
        strings.title(item),
        strings.body(item),
        item.time,
        notification,
        androidScheduleMode: mode,
      );
      try {
        await schedule(
          exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } on PlatformException catch (error) {
        if (!exact || error.code != 'exact_alarms_not_permitted') rethrow;
        exact = false;
        if (nativeIds.contains(item.id)) {
          await plugin.zonedSchedule(
            item.id,
            strings.prayer(item.kind),
            strings.prayerStart,
            item.time,
            await details(item.kind, PrayerSound.system),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } else {
          await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
        }
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
