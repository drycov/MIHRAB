import 'package:material_ui/material_ui.dart';
import '../../l10n/mihrab_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/prayer_diary.dart';
import '../../application/schedule.dart';
import '../../domain/prayer_diary.dart';
import '../../domain/prayer_schedule.dart';
import '../../domain/prayer_statistics.dart';
import '../../shared/format.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';
import 'diary_screen.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});
  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int length = 7;
  bool includeToday = false;

  @override
  Widget build(BuildContext context) {
    final key = ref.watch(localDayProvider);
    final today = DateTime.utc(key.year, key.month, key.day);
    final end = includeToday ? today : today.subtract(const Duration(days: 1));
    final period = (end: end, length: length);
    final statistics = ref.watch(prayerStatisticsProvider(period));
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Статистика намазов'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 дней')),
                ButtonSegment(value: 30, label: Text('30 дней')),
              ],
              selected: {length},
              onSelectionChanged: (v) => setState(() => length = v.single),
            ),
            IslamicCard(
              padding: EdgeInsets.zero,
              margin: const EdgeInsets.only(top: 12),
              child: SwitchListTile(
                title: const Text('Включить сегодня'),
                value: includeToday,
                onChanged: (v) => setState(() => includeToday = v),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${formatDate(end.subtract(Duration(days: length - 1)))} — ${formatDate(end)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            ...statistics.when(
              loading:
                  () => <Widget>[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
              error:
                  (_, __) => <Widget>[
                    const IslamicCard(
                      child: Text('Не удалось загрузить статистику'),
                    ),
                    TextButton(
                      onPressed:
                          () =>
                              ref.invalidate(prayerStatisticsProvider(period)),
                      child: Text(context.tr('Повторить')),
                    ),
                  ],
              data: (s) => _content(context, s),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, PrayerStatistics s) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final palette = <PrayerStatus, Color>{
      PrayerStatus.onTime: MihrabTokens.emeraldSoft,
      PrayerStatus.qada: MihrabTokens.gold,
      PrayerStatus.missed: theme.colorScheme.error,
      PrayerStatus.unmarked:
          dark
              ? MihrabTokens.gold.withValues(alpha: 0.25)
              : MihrabTokens.muted.withValues(alpha: 0.35),
    };

    return [
      MihrabFrame(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        child: Column(
          children: [
            const IslamicStar(size: 20, color: MihrabTokens.gold),
            const SizedBox(height: 12),
            Text(
              'ВЫПОЛНЕНО ПО ОТМЕТКАМ',
              style: TextStyle(
                color: MihrabTokens.gold.withValues(alpha: 0.9),
                letterSpacing: 1.8,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${s.completed} / ${s.total}',
              style: const TextStyle(
                color: MihrabTokens.paper,
                fontSize: 32,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: s.completion,
                minHeight: 4,
                backgroundColor: MihrabTokens.gold.withValues(alpha: 0.15),
                color: MihrabTokens.gold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(s.completion * 100).toStringAsFixed(1)}% · отмечено ${s.marked} / ${s.total}',
              style: TextStyle(
                color: MihrabTokens.goldSoft.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
            Text(
              'Полных дней: ${s.fullDays} / ${s.days.length}',
              style: TextStyle(
                color: MihrabTokens.gold.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
            if (s.marked == 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'За этот период пока нет записей.',
                  style: TextStyle(
                    color: MihrabTokens.goldSoft.withValues(alpha: 0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
      const IslamicSectionTitle('Распределение отметок'),
      for (final status in PrayerStatus.values) ...[
        IslamicCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(context.tr(status.label))),
                  Text(
                    '${s.count(status)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: s.total == 0 ? 0 : s.count(status) / s.total,
                  minHeight: 5,
                  backgroundColor:
                      dark ? MihrabTokens.emeraldSoft : MihrabTokens.creamMuted,
                  color: palette[status],
                ),
              ),
            ],
          ),
        ),
      ],
      const IslamicSectionTitle('По намазам'),
      for (final kind in PrayerKind.values.where((k) => k.obligatory))
        IslamicCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${kind.label}: ${s.completedFor(kind)} / ${s.days.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                kind.arabic,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color:
                      dark
                          ? MihrabTokens.gold.withValues(alpha: 0.5)
                          : MihrabTokens.muted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: [
                    for (final status in PrayerStatus.values)
                      if (s.countFor(kind, status) > 0)
                        Expanded(
                          flex: s.countFor(kind, status),
                          child: Container(height: 9, color: palette[status]),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  for (final status in PrayerStatus.values)
                    Text(
                      '${status.label}: ${s.countFor(kind, status)}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      const IslamicSectionTitle('История по дням'),
      for (final item in s.days.reversed)
        IslamicCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            title: Text(
              formatDate(item.date),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Row(
              children: [
                for (final kind in PrayerKind.values.where((k) => k.obligatory))
                  Expanded(
                    child: Tooltip(
                      message: '${kind.label}: ${item.day.status(kind).label}',
                      child: Container(
                        margin: const EdgeInsets.only(right: 3, top: 6),
                        height: 8,
                        decoration: BoxDecoration(
                          color: palette[item.day.status(kind)],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Text(
              '${item.day.completed}/5',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DiaryScreen(initialDate: item.date),
                  ),
                ),
          ),
        ),
      const SizedBox(height: 8),
      Text(
        'Статистика основана только на личных отметках. Неотмеченные намазы не считаются пропущенными. Сегодня по умолчанию исключено, поскольку день ещё не завершён.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
          height: 1.4,
        ),
      ),
    ];
  }
}
