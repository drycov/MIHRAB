import 'hijri.dart';
import 'prayer_schedule.dart';
import 'schedule_repository.dart';

class RamadanDay {
  const RamadanDay(this.date, this.hijri, this.fajr, this.maghrib, this.source);
  final DateTime date;
  final HijriDate hijri;
  final DateTime fajr, maghrib;
  final ScheduleSource source;
  Duration get fastingDuration => maghrib.difference(fajr);
  bool get isRamadan => hijri.month == 9;
  ({String label, DateTime time})? nextBoundary(DateTime now) {
    if (now.isBefore(fajr)) return (label: 'До окончания сухура', time: fajr);
    if (now.isBefore(maghrib)) return (label: 'До ифтара', time: maghrib);
    return null;
  }
}

abstract final class RamadanCalendar {
  static RamadanDay forDay(
    ScheduleRepository repository,
    City city,
    DateTime date, {
    required bool hanafi,
    int adjustment = 0,
  }) {
    final schedule = repository.getDay(city, date, hanafi: hanafi);
    return RamadanDay(
      date,
      HijriCalendar.fromGregorian(date, adjustment: adjustment),
      schedule.slots.firstWhere((p) => p.kind == PrayerKind.fajr).time,
      schedule.slots.firstWhere((p) => p.kind == PrayerKind.maghrib).time,
      schedule.source,
    );
  }

  static List<DateTime> season(DateTime today, {int adjustment = 0}) {
    final civil = DateTime.utc(today.year, today.month, today.day);
    final hijri = HijriCalendar.fromGregorian(civil, adjustment: adjustment);
    final year = hijri.month > 9 ? hijri.year + 1 : hijri.year;
    final length = HijriCalendar.start(year, 10) - HijriCalendar.start(year, 9);
    final start = DateTime.utc(
      1970,
    ).add(Duration(days: HijriCalendar.start(year, 9) - 2440588 - adjustment));
    return List.generate(length, (i) => start.add(Duration(days: i)));
  }
}
