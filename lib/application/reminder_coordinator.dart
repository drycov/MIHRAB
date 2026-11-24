import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/prayer_schedule.dart';
import '../domain/reminders.dart';
import '../infrastructure/notifications.dart';
import 'schedule.dart';
import 'settings.dart';

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
      final saved = prefs.getStringList('reminder_prayers');
      if (update == null && saved == null) return 'Уведомления не настроены';
      final enabled = update?.enabled ?? PrayerKind.values.where((p) => p.obligatory && (saved ?? []).contains(p.name)).toSet();
      final storedLead = update?.lead ?? prefs.getInt('reminder_lead') ?? 0;
      final lead = [0,5,10,15,30].contains(storedLead) ? storedLead : 0;
      final preferExact = update?.exact ?? prefs.getBool('reminder_exact') ?? false;
      if (update != null && enabled.isNotEmpty) {
        if (!await service.requestPermission()) throw StateError('Нет разрешения на уведомления.');
        if (preferExact && service.isAndroid) await service.requestExactPermission();
      }
      final settings = ref.read(settingsProvider);
      final plan = ReminderPlanner.plan(settings.city, DateTime.now(), hanafi: settings.hanafi,
        enabled: enabled, minutesBefore: lead, repository: ref.read(scheduleRepositoryProvider));
      final exact = await service.replace(plan, preferExact: preferExact);
      if (update != null) {
        await prefs.setStringList('reminder_prayers', enabled.map((p) => p.name).toList());
        await prefs.setInt('reminder_lead', lead);
        await prefs.setBool('reminder_exact', preferExact);
      }
      return 'Запланировано: ${plan.length}${service.isAndroid && plan.isNotEmpty ? (exact ? ' · точный режим' : ' · приблизительный режим') : ''}';
    });
    _tail = result.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    return result;
  }
}
