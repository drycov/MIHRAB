import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/clock.dart';
import '../../application/schedule.dart';
import '../../application/settings.dart';
import '../../domain/prayer_schedule.dart';
import '../../domain/schedule_repository.dart';
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
    final schedule = ref.watch(dailyScheduleProvider((city: key.city, hanafi: key.hanafi,
      year: date.year, month: date.month, day: date.day)));
    final slots = schedule.slots;
    final next = ref.watch(nextPrayerProvider.select((p) => p.time));
    return ListView(padding: const EdgeInsets.all(MihrabTokens.space), children: [
      Row(children: [const Icon(Icons.location_on_outlined), const SizedBox(width: 8), Expanded(child: Text(city.name))]),
      const SizedBox(height: 24),
      const CountdownCard(),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(tooltip: 'Предыдущий день', onPressed: () => setState(() => offset--), icon: const Icon(Icons.chevron_left)),
        Text(formatDate(date), style: Theme.of(context).textTheme.titleMedium),
        IconButton(tooltip: 'Следующий день', onPressed: () => setState(() => offset++), icon: const Icon(Icons.chevron_right)),
      ]),
      if (offset != 0) TextButton(onPressed: () => setState(() => offset = 0), child: const Text('Сегодня')),
      for (final slot in slots) PrayerTile(slot: slot, active: slot.time == next),
      const SizedBox(height: 16),
      Text(schedule.source == ScheduleSource.dumkCache ? 'ДУМК · сохранённое расписание' : 'Расчёт MWL. Не официальное расписание ДУМК. Сверяйте время с местной мечетью.', textAlign: TextAlign.center),
    ]);
  }
}
class CountdownCard extends ConsumerWidget {
  const CountdownCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextPrayerProvider);
    final now = ref.watch(clockProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
      decoration: const BoxDecoration(color: MihrabTokens.emerald,
        borderRadius: BorderRadius.vertical(top: Radius.elliptical(180, 85), bottom: Radius.circular(MihrabTokens.radius))),
      child: Column(children: [
        const Icon(Icons.nightlight_round, color: MihrabTokens.gold),
        const SizedBox(height: 12),
        const Text('Следующий намаз', style: TextStyle(color: MihrabTokens.gold)),
        Text(next.kind.label, style: const TextStyle(color: Colors.white, fontSize: 28)),
        Text(next.kind.arabic, style: const TextStyle(color: MihrabTokens.gold, fontSize: 22)),
        const SizedBox(height: 12),
        FittedBox(fit: BoxFit.scaleDown, child: Text(formatRemaining(next.time.difference(now)),
          style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w600))),
        Text('Начало в ${formatTime(next.time)}', style: const TextStyle(color: MihrabTokens.gold)),
      ]),
    );
  }
}
class PrayerTile extends StatelessWidget {
  const PrayerTile({super.key, required this.slot, required this.active});
  final PrayerSlot slot;
  final bool active;
  @override
  Widget build(BuildContext context) => Card(
    color: active ? MihrabTokens.emerald : null,
    child: ListTile(
      textColor: active ? Colors.white : null,
      iconColor: active ? MihrabTokens.gold : null,
      leading: Icon(switch (slot.kind) {
        PrayerKind.fajr || PrayerKind.sunrise => Icons.wb_twilight,
        PrayerKind.isha => Icons.nightlight_outlined,
        PrayerKind.maghrib => Icons.brightness_4_outlined,
        _ => Icons.wb_sunny_outlined,
      }),
      title: Text(slot.kind.label), subtitle: Text(slot.kind.arabic),
      trailing: Text(formatTime(slot.time), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    ),
  );
}
