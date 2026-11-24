import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/settings.dart';
import '../../application/reminder_coordinator.dart';
import '../../domain/prayer_schedule.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});
  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}
class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  late Set<PrayerKind> enabled;
  late int lead;
  bool busy = false;
  bool preferExact = false;
  String? status;
  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesProvider);
    final saved = prefs.getStringList('reminder_prayers') ?? [];
    enabled = PrayerKind.values.where((p) => p.obligatory && saved.contains(p.name)).toSet();
    preferExact = prefs.getBool('reminder_exact') ?? false;
    final stored = prefs.getInt('reminder_lead') ?? 0;
    lead = [0,5,10,15,30].contains(stored) ? stored : 0;
  }
  Future<void> save() async {
    setState(() { busy = true; status = null; });
    try {
      final result = await ref.read(reminderCoordinatorProvider).apply(enabled, lead, preferExact);
      if (mounted) setState(() => status = result);
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
      if (ref.watch(notificationsProvider).isAndroid)
        SwitchListTile(title: const Text('Точные уведомления'), subtitle: const Text('При отказе используется приблизительное время'), value: preferExact, onChanged: busy ? null : (v) => setState(() => preferExact = v)),
      const Text('Дополнительное напоминание'),
      DropdownButton<int>(value: lead, items: [for (final m in [0,5,10,15,30]) DropdownMenuItem(value: m, child: Text(m == 0 ? 'Нет' : 'За $m мин.'))], onChanged: busy ? null : (v) { if (v != null) setState(() => lead = v); }),
      FilledButton(onPressed: busy ? null : save, child: Text(busy ? 'Сохранение…' : 'Применить')),
      if (status != null) Text(status!),
      const Text('Расписание на шесть календарных дней обновляется при открытии приложения. Android может задерживать доставку. Используется системный звук, не запись азана.'),
    ]),
  );
}
