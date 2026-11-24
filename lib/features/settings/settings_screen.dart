import 'package:flutter/material.dart';
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
      const ListTile(title: Text('Метод расчёта'), subtitle: Text('Muslim World League (MWL)')),
    ]);
  }
}
