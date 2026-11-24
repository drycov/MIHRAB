import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'pwa_settings_card.dart';
import 'firebase_screen.dart';
import 'web_push_screen.dart';
import '../../application/locale.dart';
import '../../l10n/mihrab_strings.dart';
import 'reminder_screen.dart';
import 'adhan_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/settings.dart';
import '../../domain/prayer_schedule.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    Widget sectionTitle(String text) => IslamicSectionTitle(text);
    Widget card(List<Widget> children) => IslamicCard(
      padding: EdgeInsets.zero,
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
        sectionTitle(context.tr('Язык')),
        card([
          ListTile(
            title: Text(context.tr('Язык')),
            trailing: DropdownButton<String>(
              value: locale?.languageCode ?? 'system',
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(context.tr('Системный язык')),
                ),
                const DropdownMenuItem(value: 'ru', child: Text('Русский')),
                const DropdownMenuItem(value: 'kk', child: Text('Қазақша')),
                const DropdownMenuItem(
                  value: 'ar',
                  child: Text('العربية', textDirection: TextDirection.rtl),
                ),
                const DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                try {
                  await ref
                      .read(localeProvider.notifier)
                      .change(value == 'system' ? null : value);
                } catch (_) {
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('Не удалось сохранить язык')),
                      ),
                    );
                }
              },
            ),
          ),
        ]),
        sectionTitle(context.tr('Место и расчёт')),
        card([
          ListTile(
            title: Text(context.tr('Город')),
            subtitle: Text(context.tr(settings.city.name)),
            trailing: DropdownButton<int>(
              value: settings.cityIndex,
              underline: const SizedBox.shrink(),
              items: [
                for (var i = 0; i < City.all.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(context.tr(City.all[i].name)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) controller.city(v);
              },
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: Text(context.tr('Ханафитский Аср')),
            subtitle: Text(context.tr('Мазхаб Абу Ханифы')),
            value: settings.hanafi,
            onChanged: controller.hanafi,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            title: Text(context.tr('Метод расчёта')),
            subtitle: Text('Muslim World League (MWL)'),
          ),
        ]),
        sectionTitle(context.tr('Оформление')),
        card([
          SwitchListTile(
            title: Text(context.tr('Светлая тема')),
            subtitle: Text(
              context.tr(
                settings.light ? 'Пергамент и изумруд' : 'Ночная мечеть',
              ),
            ),
            value: settings.light,
            onChanged: controller.light,
          ),
        ]),
        sectionTitle(context.tr('Напоминания')),
        card([
          ListTile(
            leading: Icon(
              Icons.notifications_outlined,
              color: dark ? MihrabTokens.gold : MihrabTokens.emerald,
            ),
            title: Text(context.tr('Уведомления')),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReminderScreen(),
                  ),
                ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(
              Icons.library_music_outlined,
              color: dark ? MihrabTokens.gold : MihrabTokens.emerald,
            ),
            title: Text(context.tr('Записи азана')),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AdhanScreen()),
                ),
          ),
        ]),
        sectionTitle(context.tr('Прочее')),
        card([
          ListTile(
            leading: Icon(
              Icons.tune,
              color: dark ? MihrabTokens.gold : MihrabTokens.emerald,
            ),
            title: Text(context.tr('Первоначальная настройка')),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OnboardingScreen(revisit: true),
                  ),
                ),
          ),
        ]),
        if (kIsWeb) ...[
          sectionTitle('PWA'),
          const PwaSettingsCard(),
          card([ListTile(title: const Text('Web Push'), leading: const Icon(Icons.notifications_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WebPushScreen())))]),
        ],
        sectionTitle('Firebase'),
        card([ListTile(title: const Text('Firebase / FCM'), leading: const Icon(Icons.notifications_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FirebaseScreen())))]),
        const SizedBox(height: 24),
        Text(
          'MIHRAB',
          textAlign: TextAlign.center,
          style: TextStyle(
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color:
                dark
                    ? MihrabTokens.gold.withValues(alpha: 0.4)
                    : MihrabTokens.emerald.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}
