import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../domain/prayer_schedule.dart';
import 'clock.dart';
import 'settings.dart';

typedef DayKey = ({int city, bool hanafi, int year, int month, int day});
final scheduleProvider = Provider.autoDispose.family<List<PrayerSlot>, DayKey>((ref, key) =>
    PrayerSchedule.forDay(City.all[key.city], DateTime(key.year, key.month, key.day), hanafi: key.hanafi));

final localDayProvider = Provider.autoDispose<DayKey>((ref) {
  final s = ref.watch(settingsProvider);
  final now = tz.TZDateTime.from(ref.watch(clockProvider), tz.getLocation(s.city.zone));
  return (city: s.cityIndex, hanafi: s.hanafi, year: now.year, month: now.month, day: now.day);
});

final nextPrayerProvider = Provider.autoDispose<PrayerSlot>((ref) {
  final key = ref.watch(localDayProvider);
  final now = ref.watch(clockProvider);
  for (final slot in ref.watch(scheduleProvider(key))) {
    if (slot.kind.obligatory && slot.time.isAfter(now)) return slot;
  }
  final tomorrow = DateTime(key.year, key.month, key.day + 1);
  return ref.watch(scheduleProvider((city: key.city, hanafi: key.hanafi,
    year: tomorrow.year, month: tomorrow.month, day: tomorrow.day))).first;
});
