import 'package:material_ui/material_ui.dart';
import '../../l10n/mihrab_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/hijri_settings.dart';
import '../../application/schedule.dart';
import '../../domain/hijri.dart';
import '../../shared/format.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  int offset = 0;
  DateTime? selected;
  static const months = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  @override
  Widget build(BuildContext context) {
    final key = ref.watch(localDayProvider);
    final adjustment = ref.watch(hijriAdjustmentProvider);
    final today = DateTime(key.year, key.month, key.day);
    final month = DateTime(today.year, today.month + offset);
    final length = DateTime(month.year, month.month + 1, 0).day;
    final first = month.weekday - 1;
    final day = selected ?? (offset == 0 ? today : month);
    final hijri = HijriCalendar.fromGregorian(day, adjustment: adjustment);
    final schedule = ref.watch(dailyScheduleProvider((
      city: key.city,
      hanafi: key.hanafi,
      year: day.year,
      month: day.month,
      day: day.day,
    )));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text(
          HijriCalendar.fromGregorian(today, adjustment: adjustment).label,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            letterSpacing: 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('исламский календарь'),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 1.6,
            color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
          ),
        ),
        const IslamicDivider(padding: 16),
        IslamicCard(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: context.tr('Предыдущий месяц'),
                onPressed: offset <= -120
                    ? null
                    : () => setState(() {
                          offset--;
                          selected = null;
                        }),
                icon: Icon(
                  Icons.chevron_left,
                  color: dark ? MihrabTokens.gold : MihrabTokens.emerald,
                ),
              ),
              Text(
                '${context.tr(months[month.month - 1])} ${month.year}',
                style: theme.textTheme.titleMedium?.copyWith(
                  letterSpacing: 0.5,
                ),
              ),
              IconButton(
                tooltip: context.tr('Следующий месяц'),
                onPressed: offset >= 120
                    ? null
                    : () => setState(() {
                          offset++;
                          selected = null;
                        }),
                icon: Icon(
                  Icons.chevron_right,
                  color: dark ? MihrabTokens.gold : MihrabTokens.emerald,
                ),
              ),
            ],
          ),
        ),
        if (offset != 0)
          TextButton(
            onPressed: () => setState(() {
              offset = 0;
              selected = null;
            }),
            child: Text(context.tr('Сегодня')),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final name in ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'])
              Expanded(
                child: Center(
                  child: Text(
                    context.tr(name),
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 0.5,
                      color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.82,
          ),
          itemCount: first + length,
          itemBuilder: (context, i) {
            if (i < first) return const SizedBox.shrink();
            final date = DateTime(month.year, month.month, i - first + 1);
            final h = HijriCalendar.fromGregorian(date, adjustment: adjustment);
            final active = date == day;
            final isToday = date == today;
            return Padding(
              padding: const EdgeInsets.all(2),
              child: Material(
                color: active
                    ? MihrabTokens.emerald
                    : (dark
                        ? MihrabTokens.emerald.withValues(alpha: 0.25)
                        : MihrabTokens.paper),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isToday
                        ? MihrabTokens.gold
                        : (active
                            ? MihrabTokens.gold.withValues(alpha: 0.35)
                            : MihrabTokens.transparent),
                    width: isToday || active ? 1.2 : 0,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => selected = date),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: active ? MihrabTokens.paper : null,
                        ),
                      ),
                      Text(
                        '${h.day}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: active
                              ? MihrabTokens.goldSoft
                              : (dark
                                  ? MihrabTokens.gold.withValues(alpha: 0.5)
                                  : MihrabTokens.muted),
                        ),
                      ),
                      if (h.event != null)
                        Icon(
                          Icons.circle,
                          size: 5,
                          color: active
                              ? MihrabTokens.gold
                              : (dark
                                  ? MihrabTokens.goldSoft
                                  : MihrabTokens.emerald),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const IslamicDivider(),
        IslamicCard(
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDate(day),
                style: const TextStyle(
                  color: MihrabTokens.paper,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.hijriLabel(hijri),
                style: TextStyle(
                  color: MihrabTokens.goldSoft.withValues(alpha: 0.95),
                  fontSize: 15,
                ),
              ),
              if (hijri.event != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${context.tr(hijri.event!)} (${context.tr("расчётная дата")})',
                  style: TextStyle(
                    color: MihrabTokens.gold.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        IslamicSectionTitle(context.tr('Намазы дня')),
        for (final slot in schedule.slots)
          IslamicCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(slot.kind.label),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        slot.kind.arabic,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: dark
                              ? MihrabTokens.gold.withValues(alpha: 0.55)
                              : MihrabTokens.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatTime(slot.time),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        IslamicSectionTitle(context.tr('Корректировка')),
        IslamicCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            title: Text(context.tr('Смещение Хиджры')),
            trailing: DropdownButton<int>(
              value: adjustment,
              underline: const SizedBox.shrink(),
              items: [
                for (var i = -2; i <= 2; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(i > 0 ? '+$i' : '$i'),
                  ),
              ],
              onChanged: (v) async {
                if (v == null) return;
                try {
                  await ref.read(hijriAdjustmentProvider.notifier).change(v);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
