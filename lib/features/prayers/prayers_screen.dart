import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/clock.dart';
import '../../application/hijri_settings.dart';
import '../../domain/hijri.dart';
import '../../application/schedule.dart';
import '../../application/settings.dart';
import '../../domain/prayer_schedule.dart';
import '../../app/theme.dart';
import '../../shared/format.dart';

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
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MihrabTokens.space,
        MihrabTokens.spaceSm,
        MihrabTokens.space,
        MihrabTokens.spaceLg,
      ),
      children: [
        // Location + Hijri
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 18,
              color: dark ? MihrabTokens.goldSoft : MihrabTokens.emerald,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                city.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          HijriCalendar.fromGregorian(
            DateTime(key.year, key.month, key.day),
            adjustment: ref.watch(hijriAdjustmentProvider),
          ).label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: MihrabTokens.space),

        // Mihrab hero
        const CountdownCard(),
        const SizedBox(height: MihrabTokens.space),

        // Day navigator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: dark
                ? MihrabTokens.emerald.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(MihrabTokens.radius),
            border: Border.all(
              color: dark
                  ? MihrabTokens.gold.withValues(alpha: 0.12)
                  : MihrabTokens.emerald.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Предыдущий день',
                onPressed: () => setState(() => offset--),
                icon: Icon(
                  Icons.chevron_left,
                  color: dark ? MihrabTokens.gold : MihrabTokens.emerald,
                ),
              ),
              Column(
                children: [
                  Text(
                    formatDate(date),
                    style: theme.textTheme.titleMedium?.copyWith(
                      letterSpacing: 0.6,
                    ),
                  ),
                  if (offset == 0)
                    Text(
                      'сегодня',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
                        letterSpacing: 1.2,
                      ),
                    ),
                ],
              ),
              IconButton(
                tooltip: 'Следующий день',
                onPressed: () => setState(() => offset++),
                icon: Icon(
                  Icons.chevron_right,
                  color: dark ? MihrabTokens.gold : MihrabTokens.emerald,
                ),
              ),
            ],
          ),
        ),
        if (offset != 0) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => offset = 0),
              icon: const Icon(Icons.today_outlined, size: 18),
              label: const Text('Сегодня'),
              style: TextButton.styleFrom(
                foregroundColor: dark ? MihrabTokens.gold : MihrabTokens.emerald,
              ),
            ),
          ),
        ],
        const SizedBox(height: MihrabTokens.spaceSm),

        // Ornamental divider
        const _IslamicDivider(),
        const SizedBox(height: MihrabTokens.spaceSm),

        // Prayer list
        for (final slot in slots)
          PrayerTile(slot: slot, active: slot.time == next),

        const SizedBox(height: MihrabTokens.space),
        Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: dark
                ? MihrabTokens.gold.withValues(alpha: 0.45)
                : MihrabTokens.emerald.withValues(alpha: 0.35),
            fontSize: 14,
            height: 1.6,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class CountdownCard extends ConsumerWidget {
  const CountdownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextPrayerProvider);
    final now = ref.watch(clockProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MihrabTokens.emeraldSoft,
            MihrabTokens.emerald,
            MihrabTokens.emeraldDeep,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.elliptical(160, 72),
          topRight: Radius.elliptical(160, 72),
          bottomLeft: Radius.circular(MihrabTokens.radiusLg),
          bottomRight: Radius.circular(MihrabTokens.radiusLg),
        ),
        border: Border.all(
          color: MihrabTokens.gold.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: MihrabTokens.emeraldDeep.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
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
            'СЛЕДУЮЩИЙ НАМАЗ',
            style: TextStyle(
              color: MihrabTokens.gold.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            next.kind.label,
            style: const TextStyle(
              color: Colors.white,
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
                color: Colors.white,
                fontSize: 46,
                fontWeight: FontWeight.w300,
                letterSpacing: 3,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'начало в ${formatTime(next.time)}',
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
                : Colors.white),
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
        textColor: active ? Colors.white : null,
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
                  : Colors.transparent,
            ),
          ),
          child: Icon(_icon, size: 20),
        ),
        title: Text(
          slot.kind.label,
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

class _IslamicDivider extends StatelessWidget {
  const _IslamicDivider();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = dark
        ? MihrabTokens.gold.withValues(alpha: 0.35)
        : MihrabTokens.emerald.withValues(alpha: 0.25);

    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 0.8)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.brightness_1, size: 6, color: color),
        ),
        Expanded(child: Divider(color: color, thickness: 0.8)),
      ],
    );
  }
}
