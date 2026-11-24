import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/settings.dart';
import '../../application/reminder_coordinator.dart';
import '../../application/reminder_preferences.dart';
import '../../domain/prayer_schedule.dart';
import '../../domain/prayer_sound.dart';
import 'reminder_diagnostics_screen.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});
  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}
class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  late Set<PrayerKind> enabled;
  late int lead;
  Map<PrayerKind, PrayerSound> sounds = {};
  bool busy = false;
  bool preferExact = false;
  String? status;
  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesProvider);
    try {
      final config = ReminderPreferences.read(prefs);
      enabled = config?.enabled.toSet() ?? {};
      preferExact = config?.exact ?? false;
      lead = config?.lead ?? 0;
      sounds = Map.of(config?.sounds ?? {});
    } catch (_) {
      enabled = {};
      preferExact = false;
      lead = 0;
      status = 'Настройки уведомлений повреждены. Выберите параметры и примените повторно.';
    }
  }
  Future<void> save() async {
    setState(() { busy = true; status = null; });
    try {
      final result = await ref.read(reminderCoordinatorProvider).apply(enabled, lead, preferExact, sounds: sounds);
      if (mounted) setState(() => status = result);
    } catch (e) {
      if (mounted) setState(() => status = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  Future<void> preview(PrayerKind kind) async {
    setState(() {busy = true; status = null;});
    try {
      await ref.read(notificationsProvider).preview(kind, sounds[kind] ?? PrayerSound.system);
      if (mounted) setState(() => status = 'Тестовое уведомление отправлено');
    } catch (e) {
      if (mounted) setState(() => status = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Уведомления')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      for (final p in PrayerKind.values.where((p) => p.obligatory))
        Card(child: Column(children: [
          SwitchListTile(title: Text(p.label), value: enabled.contains(p), onChanged: busy ? null : (v) => setState(() { if (v) { enabled.add(p); } else { enabled.remove(p); } })),
          Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Row(children: [
            Expanded(child: DropdownButton<PrayerSound>(isExpanded:true, value:sounds[p] ?? PrayerSound.system,
              items:[for(final sound in PrayerSound.values.where((sound) => sound != PrayerSound.adhan || ref.watch(notificationsProvider).isAndroid || sounds[p] == PrayerSound.adhan)) DropdownMenuItem(value:sound,child:Text(sound.label))],
              onChanged:busy ? null : (v) {if(v!=null) setState(()=>sounds[p]=v);})),
            IconButton(tooltip:'Проверить ${p.label}',onPressed:busy ? null : ()=>preview(p),icon:const Icon(Icons.play_circle_outline)),
          ])),
        ])),
      const SizedBox(height: 16),
      if (ref.watch(notificationsProvider).isAndroid)
        SwitchListTile(title: const Text('Точные уведомления'), subtitle: const Text('При отказе используется приблизительное время'), value: preferExact, onChanged: busy ? null : (v) => setState(() => preferExact = v)),
      const Text('Дополнительное напоминание'),
      DropdownButton<int>(value: lead, items: [for (final m in [0,5,10,15,30]) DropdownMenuItem(value: m, child: Text(m == 0 ? 'Нет' : 'За $m мин.'))], onChanged: busy ? null : (v) { if (v != null) setState(() => lead = v); }),
      FilledButton(onPressed: busy ? null : save, child: Text(busy ? 'Сохранение…' : 'Применить')),
      if (status != null) Text(status!),
      ListTile(leading: const Icon(Icons.monitor_heart_outlined), title: const Text('Диагностика уведомлений'), onTap: busy ? null : () async {
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ReminderDiagnosticsScreen()));
        if (!mounted) return;
        final prefs = ref.read(preferencesProvider);
        await prefs.reload();
        if (!mounted) return;
        try {
          final config = ReminderPreferences.read(prefs);
          if (config != null) setState(() { enabled = config.enabled.toSet(); lead = config.lead; preferExact = config.exact; sounds = Map.of(config.sounds); });
        } catch (_) { if (mounted) setState(() => status = 'Не удалось прочитать настройки.'); }
      }),
      const Text('Расписание на шесть календарных дней обновляется при открытии приложения. Android может задерживать доставку. Локальный азан — экспериментальный звук уведомления Android при начале намаза. Выберите запись в настройках. При отсутствии файла и на iOS используется системный звук. На iOS вибрация зависит от системных настроек. Android может переопределять звук канала.'),
    ])),
  );
}
