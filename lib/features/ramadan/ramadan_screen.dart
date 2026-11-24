import 'package:material_ui/material_ui.dart';
import '../../l10n/mihrab_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/clock.dart';
import '../../application/hijri_settings.dart';
import '../../application/schedule.dart';
import '../../application/settings.dart';
import '../../domain/ramadan.dart';
import '../../domain/schedule_repository.dart';
import '../../shared/format.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';
import 'ramadan_reminder_screen.dart';

final ramadanSeasonProvider = Provider.autoDispose<List<RamadanDay>>((ref) {
  final key = ref.watch(localDayProvider);
  final adjustment = ref.watch(hijriAdjustmentProvider);
  final repository = ref.watch(scheduleRepositoryProvider);
  final city = ref.watch(settingsProvider.select((s) => s.city));
  final dates = RamadanCalendar.season(
    DateTime(key.year, key.month, key.day),
    adjustment: adjustment,
  );
  return dates
      .map(
        (date) => RamadanCalendar.forDay(
          repository,
          city,
          date,
          hanafi: key.hanafi,
          adjustment: adjustment,
        ),
      )
      .toList(growable: false);
});

class RamadanScreen extends ConsumerWidget {
  const RamadanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(ramadanSeasonProvider);
    final key = ref.watch(localDayProvider);
    final today = DateTime.utc(key.year, key.month, key.day);
    final city = ref.watch(settingsProvider.select((s) => s.city));
    final current = days.where((d) => d.date == today).firstOrNull;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Рамадан').toUpperCase()),
        actions: [
          IconButton(
            tooltip: context.tr('Напоминания Рамадана'),
            icon: Icon(
              Icons.notifications_outlined,
              color: dark ? MihrabTokens.gold : MihrabTokens.emerald,
            ),
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RamadanReminderScreen(),
                  ),
                ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            context.tr(city.name),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${context.tr("Рамадан")} ${days.first.hijri.year} ${context.tr("г.х.")}',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          Text(
            '${formatDate(days.first.date)} — ${formatDate(days.last.date)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
            ),
          ),
          const IslamicDivider(),
          if (current != null)
            MihrabFrame(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Column(
                children: [
                  const IslamicStar(size: 22, color: MihrabTokens.gold),
                  const SizedBox(height: 12),
                  Text(
                    '${context.tr("День")} ${current.hijri.day} ${context.tr("из")} ${days.length}',
                    style: TextStyle(
                      color: MihrabTokens.gold.withValues(alpha: 0.9),
                      letterSpacing: 2,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: current.hijri.day / days.length,
                      minHeight: 4,
                      backgroundColor: MihrabTokens.gold.withValues(
                        alpha: 0.15,
                      ),
                      color: MihrabTokens.gold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FastingCountdown(day: current),
                ],
              ),
            )
          else
            IslamicCard(
              child: ListTile(
                title: Text(context.tr('До расчётного начала Рамадана')),
                subtitle: Text('${days.first.date.difference(today).inDays}'),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            context.tr(
              'Сухур завершается к Фаджру; ифтар начинается с Магриба. Даты предварительные, сверяйте с ДУМК.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
              height: 1.4,
            ),
          ),
          IslamicSectionTitle(context.tr('Календарь поста')),
          IslamicCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    context.tr('Дата'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    context.tr('Фаджр'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    context.tr('Ифтар'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    context.tr('Пост'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final day in days)
            IslamicCard(
              highlighted: day.date == today,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDate(day.date),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                day.date == today ? MihrabTokens.paper : null,
                          ),
                        ),
                        Text(
                          '${context.tr("День")} ${day.hijri.day} · ${day.source == ScheduleSource.dumkCache ? "ДУМК" : "MWL"}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color:
                                day.date == today
                                    ? MihrabTokens.goldSoft
                                    : (dark
                                        ? MihrabTokens.gold.withValues(
                                          alpha: 0.5,
                                        )
                                        : MihrabTokens.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatTime(day.fajr),
                      style: TextStyle(
                        color: day.date == today ? MihrabTokens.paper : null,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatTime(day.maghrib),
                      style: TextStyle(
                        color: day.date == today ? MihrabTokens.paper : null,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${day.fastingDuration.inHours}:${two(day.fastingDuration.inMinutes.remainder(60))}',
                      style: TextStyle(
                        color: day.date == today ? MihrabTokens.gold : null,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class FastingCountdown extends ConsumerWidget {
  const FastingCountdown({super.key, required this.day});
  final RamadanDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider);
    final next = day.nextBoundary(now);
    return Column(
      children: [
        Text(
          context.tr(next?.label ?? 'Ифтар наступил'),
          style: TextStyle(
            color: MihrabTokens.goldSoft.withValues(alpha: 0.9),
            letterSpacing: 1.2,
            fontSize: 13,
          ),
        ),
        if (next != null) ...[
          const SizedBox(height: 8),
          Text(
            formatRemaining(next.time.difference(now)),
            style: const TextStyle(
              color: MihrabTokens.paper,
              fontSize: 40,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          '${context.tr("Фаджр")}: ${formatTime(day.fajr)}  ·  ${context.tr("Ифтар")}: ${formatTime(day.maghrib)}',
          style: TextStyle(
            color: MihrabTokens.gold.withValues(alpha: 0.8),
            fontSize: 13,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
