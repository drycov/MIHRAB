import 'package:flutter/material.dart';
import 'reminder_screen.dart';
import 'adhan_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/settings.dart';
import '../../domain/prayer_schedule.dart';
import '../../app/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(
            text.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
              color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
            ),
          ),
        );

    Widget card(List<Widget> children) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: dark
                ? MihrabTokens.emerald.withValues(alpha: 0.4)
                : Colors.white,
            borderRadius: BorderRadius.circular(MihrabTokens.radius),
            border: Border.all(
              color: dark
                  ? MihrabTokens.gold.withValues(alpha: 0.1)
                  : MihrabTokens.emerald.withValues(alpha: 0.07),
            ),
          ),
          child: Column(children: children),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MihrabTokens.space,
        MihrabTokens.spaceSm,
        MihrabTokens.space,
        MihrabTokens.spaceLg,
      ),
      children: [
        sectionTitle('Место и расчёт'),
        card([
          ListTile(
            title: const Text('Город'),
            subtitle: Text(settings.city.name),
            trailing: DropdownButton<int>(
              value: settings.cityIndex,
              underline: const SizedBox.shrink(),
              items: [
                for (var i = 0; i < City.all.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(City.all[i].name),
                  ),
              ],
              onChanged: (v) {
                if (v != null) controller.city(v);
              },
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: const Text('Ханафитский Аср'),
            subtitle: const Text('Мазхаб Абу Ханифы'),
            value: settings.hanafi,
            onChanged: controller.hanafi,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const ListTile(
            title: Text('Метод расчёта'),
            subtitle: Text('Muslim World League (MWL)'),
          ),
        ]),
        sectionTitle('Оформление'),
        card([
          SwitchListTile(
            title: const Text('Светлая тема'),
            subtitle: Text(
              settings.light ? 'Пергамент и изумруд' : 'Ночная мечеть',
            ),
            value: settings.light,
            onChanged: controller.light,
          ),
        ]),
        sectionTitle('Напоминания'),
        card([
          ListTile(
            leading: Icon(
              Icons.notifications_outlined,
              color: dark ? MihrabTokens.gold : MihrabTokens.emerald,
            ),
            title: const Text('Уведомления'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReminderScreen()),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(
              Icons.library_music_outlined,
              color: dark ? MihrabTokens.gold : MihrabTokens.emerald,
            ),
            title: const Text('Записи азана'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AdhanScreen()),
            ),
          ),
        ]),
        sectionTitle('Прочее'),
        card([
          ListTile(
            leading: Icon(
              Icons.tune,
              color: dark ? MihrabTokens.gold : MihrabTokens.emerald,
            ),
            title: const Text('Первоначальная настройка'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const OnboardingScreen(revisit: true),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        Text(
          'MIHRAB',
          textAlign: TextAlign.center,
          style: TextStyle(
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: dark
                ? MihrabTokens.gold.withValues(alpha: 0.4)
                : MihrabTokens.emerald.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}
