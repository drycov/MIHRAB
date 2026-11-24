import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/prayer_schedule.dart';
import '../domain/reminders.dart';
import '../infrastructure/notifications.dart';
import 'schedule.dart';
import 'settings.dart';
import 'reminder_preferences.dart';

final notificationsProvider = Provider<Notifications>((ref) => Notifications());
final reminderCoordinatorProvider = Provider<ReminderCoordinator>((ref) => ReminderCoordinator(ref));

class ReminderCoordinator {
  ReminderCoordinator(this.ref);
  final Ref ref;
  Future<void> _tail = Future.value();

  Future<String> refresh() => _enqueue(null);

  Future<String> apply(Set<PrayerKind> enabled, int lead, bool exact) =>
      _enqueue((enabled: Set<PrayerKind>.of(enabled), lead: lead, exact: exact));

  Future<String> _enqueue(({Set<PrayerKind> enabled, int lead, bool exact})? update) {
    final result = _tail.then((_) async {
      final service = ref.read(notificationsProvider);
      if (!service.supported) return 'Уведомления недоступны на этой платформе';
      final prefs = ref.read(preferencesProvider);
      final config = update == null ? ReminderPreferences.read(prefs) :
          ReminderPreferences(enabled: update.enabled, lead: update.lead, exact: update.exact);
      if (config == null) return 'Уведомления не настроены';
      final enabled = config.enabled;
      final lead = config.lead;
      final preferExact = config.exact;
      if (update != null && enabled.isNotEmpty) {
        if (!await service.requestPermission()) throw StateError('Нет разрешения на уведомления.');
        if (preferExact && service.isAndroid) await service.requestExactPermission();
      }
      // Persist desired state before scheduling so a retry can recover after failure.
      await config.save(prefs);
      final settings = ref.read(settingsProvider);
      final plan = ReminderPlanner.plan(settings.city, DateTime.now(), hanafi: settings.hanafi,
        enabled: enabled, minutesBefore: lead, repository: ref.read(scheduleRepositoryProvider));
      final exact = await service.replace(plan, preferExact: preferExact);
      return 'Запланировано: ${plan.length}${service.isAndroid && plan.isNotEmpty ? (exact ? ' · точный режим' : ' · приблизительный режим') : ''}';
    });
    _tail = result.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    return result;
  }
}
