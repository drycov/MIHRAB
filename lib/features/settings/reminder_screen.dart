import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/settings.dart';
import '../../application/schedule.dart';
import '../../domain/prayer_schedule.dart';
import '../../domain/reminders.dart';
import '../../infrastructure/notifications.dart';

final notificationsProvider = Provider<Notifications>((ref) => Notifications());

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});
  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}
class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  late Set<PrayerKind> enabled;
  late int lead;
  bool busy = false;
  String? status;
  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesProvider);
    final saved = prefs.getStringList('reminder_prayers') ?? [];
    enabled = PrayerKind.values.where((p) => p.obligatory && saved.contains(p.name)).toSet();
    final stored = prefs.getInt('reminder_lead') ?? 0;
    lead = [0,5,10,15,30].contains(stored) ? stored : 0;
  }
  Future<void> save() async {
    setState(() { busy = true; status = null; });
    try {
      final service = ref.read(notificationsProvider);
      if (!service.supported) throw StateError('Уведомления доступны на Android и iOS.');
      if (enabled.isNotEmpty && !await service.requestPermission()) {
        throw StateError('Нет разрешения на уведомления.');
      }
      final settings = ref.read(settingsProvider);
      final plan = ReminderPlanner.plan(settings.city, DateTime.now(), hanafi: settings.hanafi, enabled: enabled, minutesBefore: lead, repository: ref.read(scheduleRepositoryProvider));
      await service.replace(plan);
      final prefs = ref.read(preferencesProvider);
      await prefs.setStringList('reminder_prayers', enabled.map((p) => p.name).toList());
      await prefs.setInt('reminder_lead', lead);
      if (mounted) setState(() => status = 'Запланировано уведомлений: ${plan.length}');
    } catch (e) {
      if (mounted) setState(() => status = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Уведомления')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      for (final p in PrayerKind.values.where((p) => p.obligatory))
        SwitchListTile(title: Text(p.label), value: enabled.contains(p), onChanged: busy ? null : (v) => setState(() { if (v) { enabled.add(p); } else { enabled.remove(p); } })),
      const SizedBox(height: 16),
      const Text('Дополнительное напоминание'),
      DropdownButton<int>(value: lead, items: [for (final m in [0,5,10,15,30]) DropdownMenuItem(value: m, child: Text(m == 0 ? 'Нет' : 'За $m мин.'))], onChanged: busy ? null : (v) { if (v != null) setState(() => lead = v); }),
      FilledButton(onPressed: busy ? null : save, child: Text(busy ? 'Сохранение…' : 'Применить')),
      if (status != null) Text(status!),
      const Text('Расписание на шесть календарных дней. Android может задерживать доставку. Используется системный звук, не запись азана.'),
    ]),
  );
}
