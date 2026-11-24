import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/settings.dart';
import '../../application/reminder_coordinator.dart';
import '../../application/reminder_preferences.dart';
import '../../domain/prayer_schedule.dart';
import '../../domain/prayer_sound.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';
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
      status =
          'Настройки уведомлений повреждены. Выберите параметры и примените повторно.';
    }
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      status = null;
    });
    try {
      final result = await ref.read(reminderCoordinatorProvider).apply(
            enabled,
            lead,
            preferExact,
            sounds: sounds,
          );
      if (mounted) setState(() => status = result);
    } catch (e) {
      if (mounted) setState(() => status = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> preview(PrayerKind kind) async {
    setState(() {
      busy = true;
      status = null;
    });
    try {
      await ref.read(notificationsProvider).preview(
            kind,
            sounds[kind] ?? PrayerSound.system,
          );
      if (mounted) setState(() => status = 'Тестовое уведомление отправлено');
    } catch (e) {
      if (mounted) setState(() => status = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? MihrabTokens.gold : MihrabTokens.emerald;

    return Scaffold(
      appBar: AppBar(title: const Text('УВЕДОМЛЕНИЯ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            const IslamicSectionTitle('Намазы'),
            for (final p in PrayerKind.values.where((p) => p.obligatory))
              IslamicCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(p.label),
                      subtitle: Text(
                        p.arabic,
                        textDirection: TextDirection.rtl,
                      ),
                      value: enabled.contains(p),
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                                if (v) {
                                  enabled.add(p);
                                } else {
                                  enabled.remove(p);
                                }
                              }),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<PrayerSound>(
                              isExpanded: true,
                              value: sounds[p] ?? PrayerSound.system,
                              underline: const SizedBox.shrink(),
                              items: [
                                for (final sound in PrayerSound.values.where(
                                  (sound) =>
                                      sound != PrayerSound.adhan ||
                                      ref.watch(notificationsProvider).isAndroid ||
                                      sounds[p] == PrayerSound.adhan,
                                ))
                                  DropdownMenuItem(
                                    value: sound,
                                    child: Text(sound.label),
                                  ),
                              ],
                              onChanged: busy
                                  ? null
                                  : (v) {
                                      if (v != null) {
                                        setState(() => sounds[p] = v);
                                      }
                                    },
                            ),
                          ),
                          IconButton(
                            tooltip: 'Проверить ${p.label}',
                            onPressed: busy ? null : () => preview(p),
                            icon: Icon(Icons.play_circle_outline, color: accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const IslamicSectionTitle('Параметры'),
            if (ref.watch(notificationsProvider).isAndroid)
              IslamicCard(
                padding: EdgeInsets.zero,
                child: SwitchListTile(
                  title: const Text('Точные уведомления'),
                  subtitle: const Text(
                    'При отказе используется приблизительное время',
                  ),
                  value: preferExact,
                  onChanged:
                      busy ? null : (v) => setState(() => preferExact = v),
                ),
              ),
            IslamicCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                title: const Text('Дополнительное напоминание'),
                trailing: DropdownButton<int>(
                  value: lead,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final m in [0, 5, 10, 15, 30])
                      DropdownMenuItem(
                        value: m,
                        child: Text(m == 0 ? 'Нет' : 'За $m мин.'),
                      ),
                  ],
                  onChanged: busy
                      ? null
                      : (v) {
                          if (v != null) setState(() => lead = v);
                        },
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy ? null : save,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor:
                    dark ? MihrabTokens.background : MihrabTokens.cream,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MihrabTokens.radius),
                ),
              ),
              child: Text(busy ? 'Сохранение…' : 'Применить'),
            ),
            if (status != null) ...[
              const SizedBox(height: 12),
              Text(status!),
            ],
            const IslamicDivider(),
            IslamicCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.monitor_heart_outlined, color: accent),
                title: const Text('Диагностика уведомлений'),
                trailing: const Icon(Icons.chevron_right),
                onTap: busy
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ReminderDiagnosticsScreen(),
                          ),
                        );
                        if (!mounted) return;
                        final prefs = ref.read(preferencesProvider);
                        await prefs.reload();
                        if (!mounted) return;
                        try {
                          final config = ReminderPreferences.read(prefs);
                          if (config != null) {
                            setState(() {
                              enabled = config.enabled.toSet();
                              lead = config.lead;
                              preferExact = config.exact;
                              sounds = Map.of(config.sounds);
                            });
                          }
                        } catch (_) {
                          if (mounted) {
                            setState(
                              () => status = 'Не удалось прочитать настройки.',
                            );
                          }
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
