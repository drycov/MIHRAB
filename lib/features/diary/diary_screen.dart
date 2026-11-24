import 'package:flutter/material.dart';
import '../../l10n/mihrab_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/prayer_diary.dart';
import '../../application/widget_sync.dart';
import '../../application/schedule.dart';
import '../../domain/prayer_diary.dart';
import '../../domain/prayer_schedule.dart';
import '../../shared/format.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';
import 'statistics_screen.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key, this.initialDate});
  final DateTime? initialDate;
  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  DateTime? selected;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    selected = widget.initialDate;
  }

  Future<void> mark(DateTime date, PrayerKind kind, PrayerStatus status) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await ref.read(diaryRepositoryProvider).mark(date, kind, status);
      if (mounted) {
        ref.invalidate(diaryDayProvider(date));
        ref.invalidate(prayerStatisticsProvider);
        await ref.read(widgetSyncProvider).refresh();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить запись')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = ref.watch(localDayProvider);
    final today = DateTime.utc(key.year, key.month, key.day);
    final date =
        selected == null || selected!.isAfter(today) ? today : selected!;
    final supported = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? MihrabTokens.gold : MihrabTokens.emerald;

    if (!supported) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Дневник намазов'))),
        body: const Center(
          child: Text('Локальный дневник недоступен на этой платформе'),
        ),
      );
    }

    final day = ref.watch(diaryDayProvider(date));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Дневник намазов')),
        actions: [
          IconButton(
            tooltip: context.tr('Статистика'),
            icon: Icon(Icons.bar_chart, color: accent),
            onPressed: busy
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const StatisticsScreen(),
                      ),
                    ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            IslamicCard(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: context.tr('Предыдущий день'),
                    onPressed: busy || !date.isAfter(DateTime.utc(2000))
                        ? null
                        : () => setState(
                              () => selected =
                                  date.subtract(const Duration(days: 1)),
                            ),
                    icon: Icon(Icons.chevron_left, color: accent),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.calendar_today, size: 18, color: accent),
                    label: Text(
                      formatDate(date),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: dark ? MihrabTokens.cream : MihrabTokens.ink,
                      ),
                    ),
                    onPressed: busy
                        ? null
                        : () async {
                            final result = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime(date.year, date.month, date.day),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(
                                today.year,
                                today.month,
                                today.day,
                              ),
                            );
                            if (result != null && mounted) {
                              setState(
                                () => selected = DateTime.utc(
                                  result.year,
                                  result.month,
                                  result.day,
                                ),
                              );
                            }
                          },
                  ),
                  IconButton(
                    tooltip: context.tr('Следующий день'),
                    onPressed: busy || !date.isBefore(today)
                        ? null
                        : () => setState(
                              () =>
                                  selected = date.add(const Duration(days: 1)),
                            ),
                    icon: Icon(Icons.chevron_right, color: accent),
                  ),
                ],
              ),
            ),
            if (date != today)
              TextButton(
                onPressed: busy ? null : () => setState(() => selected = null),
                child: Text(context.tr('Сегодня')),
              ),
            ...day.when(
              loading: () => <Widget>[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, s) => <Widget>[
                const IslamicCard(child: Text('Не удалось открыть дневник')),
                TextButton(
                  onPressed: () => ref.invalidate(diaryDayProvider(date)),
                  child: Text(context.tr('Повторить')),
                ),
              ],
              data: (value) => <Widget>[
                MihrabFrame(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: Column(
                    children: [
                      const IslamicStar(size: 20, color: MihrabTokens.gold),
                      const SizedBox(height: 12),
                      Text(
                        'ВЫПОЛНЕНО',
                        style: TextStyle(
                          color: MihrabTokens.gold.withValues(alpha: 0.9),
                          letterSpacing: 2.2,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${value.completed} из 5',
                        style: const TextStyle(
                          color: MihrabTokens.paper,
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value.completed / 5,
                          minHeight: 4,
                          backgroundColor:
                              MihrabTokens.gold.withValues(alpha: 0.15),
                          color: MihrabTokens.gold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Своевременно: ${value.count(PrayerStatus.onTime)}  ·  Восполнено: ${value.count(PrayerStatus.qada)}',
                        style: TextStyle(
                          color: MihrabTokens.goldSoft.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Пропущено: ${value.count(PrayerStatus.missed)}  ·  Не отмечено: ${value.count(PrayerStatus.unmarked)}',
                        style: TextStyle(
                          color: MihrabTokens.gold.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const IslamicSectionTitle('Отметки'),
                for (final kind
                    in PrayerKind.values.where((k) => k.obligatory))
                  IslamicCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kind.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          kind.arabic,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: dark
                                ? MihrabTokens.gold.withValues(alpha: 0.55)
                                : MihrabTokens.muted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<PrayerStatus>(
                          isExpanded: true,
                          value: value.status(kind),
                          underline: const SizedBox.shrink(),
                          items: [
                            for (final status in PrayerStatus.values)
                              DropdownMenuItem(
                                value: status,
                                child: Text(context.tr(status.label)),
                              ),
                          ],
                          onChanged: busy
                              ? null
                              : (status) {
                                  if (status != null) {
                                    mark(date, kind, status);
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (busy) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 12),
            Text(
              'Отметки личные и задаются вручную. Неотмеченный намаз не считается пропущенным. Записи привязаны к выбранной календарной дате и не изменяются при смене города.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
