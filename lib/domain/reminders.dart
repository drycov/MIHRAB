import 'package:timezone/timezone.dart' as tz;
import 'prayer_schedule.dart';
import 'schedule_repository.dart';

class PrayerReminder {
  const PrayerReminder(this.id, this.kind, this.time, this.minutesBefore);
  final int id, minutesBefore;
  final PrayerKind kind;
  final tz.TZDateTime time;
}

abstract final class ReminderPlanner {
  // Reserve a separate namespace; IDs are tied to the prayer's civil date,
  // not its position in the rolling six-day window.
  static const idBase = 100000000;
  static const idLimit = 200000000;
  static bool ownsId(int id) => (id >= 1000 && id < 1120) ||
      (id >= idBase && id < idLimit);
  static int stableId(DateTime date, PrayerKind kind, bool early) {
    final day = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(2000)).inDays;
    final id = idBase + day * 16 + kind.index * 2 + (early ? 1 : 0);
    if (id < idBase || id >= idLimit) throw RangeError('Unsupported reminder date');
    return id;
  }

  static List<PrayerReminder> plan(City city, DateTime now,
      {required bool hanafi, required Set<PrayerKind> enabled, required int minutesBefore, ScheduleRepository? repository}) {
    final local = tz.TZDateTime.from(now, tz.getLocation(city.zone));
    final result = <PrayerReminder>[];
    for (var day = 0; day < 6; day++) {
      final date = DateTime(local.year, local.month, local.day + day);
      final slots = repository?.getDay(city, date, hanafi: hanafi).slots ?? PrayerSchedule.forDay(city, date, hanafi: hanafi);
      for (final slot in slots) {
        if (!slot.kind.obligatory || !enabled.contains(slot.kind)) continue;
        for (final lead in {0, if (minutesBefore > 0) minutesBefore}) {
          final time = slot.time.subtract(Duration(minutes: lead));
          if (!time.isAfter(now)) continue;
          result.add(PrayerReminder(stableId(date, slot.kind, lead > 0),
              slot.kind, time, lead));
        }
      }
    }
    result.sort((a,b) => a.time.compareTo(b.time));
    return result;
  }
}
