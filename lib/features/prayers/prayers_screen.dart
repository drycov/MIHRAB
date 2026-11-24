import 'package:flutter/material.dart';
import '../../l10n/mihrab_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/clock.dart';
import '../../application/hijri_settings.dart';
import '../../domain/hijri.dart';
import '../../application/schedule.dart';
import '../../application/settings.dart';
import '../../domain/prayer_schedule.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';
import '../../shared/format.dart';
import '../diary/diary_screen.dart';

class PrayersScreen extends ConsumerStatefulWidget {
  const PrayersScreen({super.key});
  @override
  ConsumerState<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends ConsumerState<PrayersScreen> {
  int offset = 0;

  @override
  Widget build(BuildContext context) {
    final key = ref.watch(localDayProvider);
    final city = ref.watch(settingsProvider.select((s) => s.city));
    final date = DateTime(key.year, key.month, key.day + offset);
    final schedule = ref.watch(dailyScheduleProvider((
      city: key.city,
      hanafi: key.hanafi,
      year: date.year,
      month: date.month,
      day: date.day,
    )));
    final slots = schedule.slots;
    final next = ref.watch(nextPrayerProvider.select((p) => p.time));
    return ListView(padding: const EdgeInsets.all(MihrabTokens.space), children: [
      Row(children: [const Icon(Icons.location_on_outlined), const SizedBox(width: 8), Expanded(child: Text(context.tr(city.name)))]),
      Text(HijriCalendar.fromGregorian(DateTime(key.year,key.month,key.day), adjustment: ref.watch(hijriAdjustmentProvider)).label, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      const CountdownCard(),
      ListTile(leading: const Icon(Icons.fact_check_outlined), title: Text(context.tr('Дневник намазов')), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DiaryScreen()))),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(tooltip: context.tr('Предыдущий день'), onPressed: () => setState(() => offset--), icon: const Icon(Icons.chevron_left)),
        Text(formatDate(date), style: Theme.of(context).textTheme.titleMedium),
        IconButton(tooltip: context.tr('Следующий день'), onPressed: () => setState(() => offset++), icon: const Icon(Icons.chevron_right)),
      ]),
      if (offset != 0) TextButton(onPressed: () => setState(() => offset = 0), child: Text(context.tr('Сегодня'))),
      for (final slot in slots) PrayerTile(slot: slot, active: slot.time == next),
      const SizedBox(height: 16),
      Text(context.tr(schedule.source == ScheduleSource.dumkCache ? 'ДУМК · сохранённое расписание' : 'Расчёт MWL. Не официальное расписание ДУМК. Сверяйте время с местной мечетью.'), textAlign: TextAlign.center),
    ]);
  }
}

class CountdownCard extends ConsumerWidget {
  const CountdownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextPrayerProvider);
    final now = ref.watch(clockProvider);

    return MihrabFrame(
      child: Column(
        children: [
          // Crescent ornament
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: MihrabTokens.gold.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.nightlight_round,
              color: MihrabTokens.gold,
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('СЛЕДУЮЩИЙ НАМАЗ'),
            style: TextStyle(
              color: MihrabTokens.gold.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(next.kind.label),
            style: const TextStyle(
              color: MihrabTokens.paper,
              fontSize: 30,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            next.kind.arabic,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: MihrabTokens.goldSoft.withValues(alpha: 0.95),
              fontSize: 24,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          // Gold line
          Container(
            width: 48,
            height: 1.5,
            decoration: BoxDecoration(
              color: MihrabTokens.gold.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatRemaining(next.time.difference(now)),
              style: const TextStyle(
                color: MihrabTokens.paper,
                fontSize: 46,
                fontWeight: FontWeight.w300,
                letterSpacing: 3,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${context.tr('начало в')} ${formatTime(next.time)}',
            style: TextStyle(
              color: MihrabTokens.gold.withValues(alpha: 0.85),
              fontSize: 14,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class PrayerTile extends StatelessWidget {
  const PrayerTile({super.key, required this.slot, required this.active});
  final PrayerSlot slot;
  final bool active;

  IconData get _icon => switch (slot.kind) {
        PrayerKind.fajr || PrayerKind.sunrise => Icons.wb_twilight,
        PrayerKind.isha => Icons.nightlight_outlined,
        PrayerKind.maghrib => Icons.brightness_4_outlined,
        _ => Icons.wb_sunny_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? MihrabTokens.emerald
            : (dark
                ? MihrabTokens.emerald.withValues(alpha: 0.35)
                : MihrabTokens.paper),
        borderRadius: BorderRadius.circular(MihrabTokens.radius),
        border: Border.all(
          color: active
              ? MihrabTokens.gold.withValues(alpha: 0.45)
              : (dark
                  ? MihrabTokens.gold.withValues(alpha: 0.08)
                  : MihrabTokens.emerald.withValues(alpha: 0.07)),
          width: active ? 1.2 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: MihrabTokens.emerald.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        textColor: active ? MihrabTokens.paper : null,
        iconColor: active
            ? MihrabTokens.gold
            : (dark ? MihrabTokens.goldSoft : MihrabTokens.emerald),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? MihrabTokens.gold.withValues(alpha: 0.15)
                : (dark
                    ? MihrabTokens.background.withValues(alpha: 0.4)
                    : MihrabTokens.cream),
            border: Border.all(
              color: active
                  ? MihrabTokens.gold.withValues(alpha: 0.35)
                  : MihrabTokens.transparent,
            ),
          ),
          child: Icon(_icon, size: 20),
        ),
        title: Text(
          context.tr(slot.kind.label),
          style: TextStyle(
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        subtitle: Text(
          slot.kind.arabic,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: active
                ? MihrabTokens.goldSoft
                : (dark
                    ? MihrabTokens.gold.withValues(alpha: 0.55)
                    : MihrabTokens.muted),
            fontSize: 15,
          ),
        ),
        trailing: Text(
          formatTime(slot.time),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: active ? MihrabTokens.gold : null,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

