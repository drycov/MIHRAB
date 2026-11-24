import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/prayer_schedule.dart';
import '../domain/prayer_sound.dart';
import '../domain/reminders.dart';
import '../infrastructure/notifications.dart';
import '../infrastructure/reminder_lock.dart';
import 'schedule.dart';
import 'settings.dart';
import 'reminder_preferences.dart';
import 'reminder_queue.dart';
import 'ramadan_reminder_preferences.dart';
import '../domain/ramadan_reminders.dart';

final notificationsProvider = Provider<Notifications>((ref) => Notifications());
final reminderCoordinatorProvider = Provider<ReminderCoordinator>(
  (ref) => ReminderCoordinator(ref),
);

class ReminderCoordinator {
  ReminderCoordinator(this.ref);
  final Ref ref;
  final ReminderQueue _queue = ReminderQueue();

  Future<String> refresh() => _enqueue(null);

  Future<String> apply(
    Set<PrayerKind> enabled,
    int lead,
    bool exact, {
    Map<PrayerKind, PrayerSound>? sounds,
  }) => _enqueue((
    enabled: Set<PrayerKind>.of(enabled),
    lead: lead,
    exact: exact,
    sounds: sounds == null ? null : Map<PrayerKind, PrayerSound>.of(sounds),
  ));

  Future<String> _enqueue(
    ({
      Set<PrayerKind> enabled,
      int lead,
      bool exact,
      Map<PrayerKind, PrayerSound>? sounds,
    })?
    update,
  ) {
    return _queue.run(() async {
      final service = ref.read(notificationsProvider);
      if (!service.supported) return 'Уведомления недоступны на этой платформе';
      final prefs = ref.read(preferencesProvider);
      // Permission prompts must happen outside the database transaction.
      if (update != null && update.enabled.isNotEmpty) {
        if (!await service.requestPermission())
          throw StateError('Нет разрешения на уведомления.');
        if (update.exact && service.isAndroid)
          await service.requestExactPermission();
      }
      return ReminderLock.run(() async {
        await prefs.reload();
        final config =
            update == null
                ? ReminderPreferences.read(prefs)
                : ReminderPreferences(
                  enabled: update.enabled,
                  lead: update.lead,
                  exact: update.exact,
                  sounds:
                      update.sounds ??
                      ReminderPreferences.read(prefs)?.sounds ??
                      const {},
                );
        final ramadan = RamadanReminderPreferences.read(prefs);
        if (config == null && !ramadan.enabled) {
          await service.replace([]);
          return 'Уведомления не настроены';
        }
        final enabled = config?.enabled ?? <PrayerKind>{};
        final lead = config?.lead ?? 0;
        final preferExact = config?.exact ?? false;
        // Persist desired state before scheduling so a retry can recover after failure.
        if (config != null &&
            (update != null || !prefs.containsKey(ReminderPreferences.key)))
          await config.save(prefs);
        final settings = ref.read(settingsProvider);
        final plan = ReminderPlanner.plan(
          settings.city,
          DateTime.now(),
          hanafi: settings.hanafi,
          enabled: enabled,
          minutesBefore: lead,
          repository: ref.read(scheduleRepositoryProvider),
        );
        plan.addAll(
          RamadanReminderPlanner.plan(
            settings.city,
            DateTime.now(),
            hanafi: settings.hanafi,
            config: ramadan,
            adjustment:
                (prefs.getInt('hijri_adjustment') ?? 0).clamp(-2, 2).toInt(),
            repository: ref.read(scheduleRepositoryProvider),
          ),
        );
        final exact = await service.replace(
          plan,
          preferExact: preferExact,
          sounds: config?.sounds ?? const {},
        );
        await prefs.setString(
          'reminder_last_success',
          DateTime.now().toUtc().toIso8601String(),
        );
        return 'Запланировано: ${plan.length}${service.isAndroid && plan.isNotEmpty ? (exact ? ' · точный режим' : ' · приблизительный режим') : ''}';
      });
    });
  }
}
