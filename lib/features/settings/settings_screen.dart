import 'package:flutter/material.dart';
import 'reminder_screen.dart';
import 'adhan_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/settings.dart';
import '../../domain/prayer_schedule.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Город', style: Theme.of(context).textTheme.titleMedium),
      DropdownButton<int>(isExpanded: true, value: settings.cityIndex,
        items: [for (var i = 0; i < City.all.length; i++) DropdownMenuItem(value: i, child: Text(City.all[i].name))],
        onChanged: (v) { if (v != null) controller.city(v); }),
      SwitchListTile(title: const Text('Ханафитский Аср'), value: settings.hanafi, onChanged: controller.hanafi),
      SwitchListTile(title: const Text('Светлая тема'), value: settings.light, onChanged: controller.light),
      ListTile(leading: const Icon(Icons.notifications_outlined), title: const Text('Уведомления'), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ReminderScreen()))),
      ListTile(leading: const Icon(Icons.library_music_outlined), title: const Text('Записи азана'), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AdhanScreen()))),
      ListTile(leading: const Icon(Icons.tune), title: const Text('Первоначальная настройка'), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OnboardingScreen(revisit: true)))),
      const ListTile(title: Text('Метод расчёта'), subtitle: Text('Muslim World League (MWL)')),
    ]);
  }
}
