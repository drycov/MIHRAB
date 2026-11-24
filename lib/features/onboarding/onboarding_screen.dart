import 'package:flutter/material.dart';
import '../../l10n/mihrab_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/onboarding.dart';
import '../../application/settings.dart';
import '../../application/reminder_coordinator.dart';
import '../../application/reminder_preferences.dart';
import '../../domain/prayer_schedule.dart';
import '../../domain/prayer_sound.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.revisit = false});
  final bool revisit;
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int step = 0;
  late int city;
  late bool hanafi, light;
  bool notifications = false;
  bool exact = false;
  bool busy = false;
  PrayerSound sound = PrayerSound.system;
  String? message;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    city = settings.cityIndex;
    hanafi = settings.hanafi;
    light = settings.light;
  }

  Future<void> finish({bool skipNotifications = false}) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final controller = ref.read(settingsProvider.notifier);
      final coordinator = ref.read(reminderCoordinatorProvider);
      final onboarding = ref.read(onboardingProvider.notifier);
      final prefs = ref.read(preferencesProvider);
      await controller.city(city);
      await controller.hanafi(hanafi);
      await controller.light(light);
      if (notifications && !skipNotifications) {
        final enabled =
            PrayerKind.values.where((p) => p.obligatory).toSet();
        final existing = ReminderPreferences.read(prefs);
        await coordinator.apply(
          enabled,
          existing?.lead ?? 0,
          exact,
          sounds: {for (final p in enabled) p: sound},
        );
      }
      await onboarding.complete();
      if (mounted && widget.revisit) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => message =
            'Не удалось завершить настройку. Проверьте разрешения или продолжите без настройки уведомлений.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(notificationsProvider);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MIHRAB',
          style: TextStyle(
            letterSpacing: MihrabTokens.letterTitle,
            fontWeight: FontWeight.w600,
            color: dark ? MihrabTokens.goldSoft : MihrabTokens.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (step + 1) / 3,
                  minHeight: 3,
                  backgroundColor: dark
                      ? MihrabTokens.emeraldSoft
                      : MihrabTokens.creamMuted,
                  color: dark ? MihrabTokens.gold : MihrabTokens.emerald,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Text(
                    '${context.tr("Шаг")} ${step + 1} ${context.tr("из")} 3',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color:
                          dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (step == 0) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: dark
                                ? MihrabTokens.gold.withValues(alpha: 0.35)
                                : MihrabTokens.emerald.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.mosque_outlined,
                          size: 64,
                          color: dark
                              ? MihrabTokens.gold
                              : MihrabTokens.emerald,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(context.tr('Добро пожаловать\nв MIHRAB'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(context.tr('Время намазов, направление Киблы, исламский календарь и напоминания — в одном спокойном приложении.'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: dark
                            ? MihrabTokens.goldSoft
                            : MihrabTokens.muted,
                        height: 1.45,
                      ),
                    ),
                    const IslamicDivider(padding: 28),
                    Text(
                      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: dark
                            ? MihrabTokens.gold.withValues(alpha: 0.5)
                            : MihrabTokens.emerald.withValues(alpha: 0.4),
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                  if (step == 1) ...[
                    Text(context.tr('Город и настройки'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    IslamicCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(context.tr('Город')),
                            trailing: DropdownButton<int>(
                              value: city,
                              underline: const SizedBox.shrink(),
                              items: [
                                for (var i = 0; i < City.all.length; i++)
                                  DropdownMenuItem(
                                    value: i,
                                    child: Text(context.tr(City.all[i].name)),
                                  ),
                              ],
                              onChanged: busy
                                  ? null
                                  : (v) {
                                      if (v != null) setState(() => city = v);
                                    },
                            ),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          SwitchListTile(
                            title: Text(context.tr('Ханафитский Аср')),
                            subtitle: Text(context.tr('Метод определения времени Асра')),
                            value: hanafi,
                            onChanged: busy
                                ? null
                                : (v) => setState(() => hanafi = v),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          SwitchListTile(
                            title: Text(context.tr('Светлая тема')),
                            subtitle: Text(
                              context.tr(light ? 'Пергамент и изумруд' : 'Ночная мечеть'),
                            ),
                            value: light,
                            onChanged: busy
                                ? null
                                : (v) => setState(() => light = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (step == 2) ...[
                    Text(
                      context.tr('Напоминания'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!service.supported)
                      IslamicCard(
                        child: Text(context.tr('На этой платформе системные уведомления недоступны.'),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    IslamicCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text(context.tr('Напоминать о пяти намазах')),
                            value: notifications,
                            onChanged: busy || !service.supported
                                ? null
                                : (v) => setState(() => notifications = v),
                          ),
                          if (notifications) ...[
                            if (service.isAndroid) ...[
                              const Divider(
                                  height: 1, indent: 16, endIndent: 16),
                              SwitchListTile(
                                title: Text(context.tr('Точные уведомления')),
                                subtitle: Text(context.tr('Android может запросить дополнительное разрешение'),
                                ),
                                value: exact,
                                onChanged: busy
                                    ? null
                                    : (v) => setState(() => exact = v),
                              ),
                            ],
                            const Divider(
                                height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              title: Text(context.tr('Звук')),
                              trailing: DropdownButton<PrayerSound>(
                                value: sound,
                                underline: const SizedBox.shrink(),
                                items: [
                                  for (final s in [
                                    PrayerSound.system,
                                    if (service.isAndroid)
                                      PrayerSound.vibration,
                                    PrayerSound.silent,
                                  ])
                                    DropdownMenuItem(
                                      value: s,
                                      child: Text(context.tr(s.label)),
                                    ),
                                ],
                                onChanged: busy
                                    ? null
                                    : (v) {
                                        if (v != null) {
                                          setState(() => sound = v);
                                        }
                                      },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(context.tr('Разрешение будет запрошено только после завершения настройки. Записи азана можно добавить позже.'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: dark
                            ? MihrabTokens.goldSoft
                            : MihrabTokens.muted,
                      ),
                    ),
                  ],
                  if (step == 2)
                    Text(context.tr('Если пропустить уведомления, существующие настройки не изменятся.')),
                  if (message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      context.tr(message!),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (busy) const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : step < 2
                            ? () => setState(() => step++)
                            : () => finish(),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          dark ? MihrabTokens.gold : MihrabTokens.emerald,
                      foregroundColor: dark
                          ? MihrabTokens.background
                          : MihrabTokens.cream,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(MihrabTokens.radius),
                      ),
                    ),
                    child: Text(context.tr(step < 2 ? 'Далее' : 'Завершить')),
                  ),
                  if (step > 0)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                                step--;
                                message = null;
                              }),
                      child: Text(context.tr('Назад')),
                    ),
                  if (step == 2 && notifications)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => finish(skipNotifications: true),
                      child: Text(context.tr('Продолжить без настройки уведомлений'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
