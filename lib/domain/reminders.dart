import 'package:timezone/timezone.dart' as tz;
import 'prayer_schedule.dart';

class PrayerReminder {
  const PrayerReminder(this.id, this.kind, this.time, this.minutesBefore);
  final int id, minutesBefore;
  final PrayerKind kind;
  final tz.TZDateTime time;
}

abstract final class ReminderPlanner {
  static List<PrayerReminder> plan(City city, DateTime now,
      {required bool hanafi, required Set<PrayerKind> enabled, required int minutesBefore}) {
    final local = tz.TZDateTime.from(now, tz.getLocation(city.zone));
    final result = <PrayerReminder>[];
    for (var day = 0; day < 6; day++) {
      final date = DateTime(local.year, local.month, local.day + day);
      for (final slot in PrayerSchedule.forDay(city, date, hanafi: hanafi)) {
        if (!slot.kind.obligatory || !enabled.contains(slot.kind)) continue;
        for (final lead in {0, if (minutesBefore > 0) minutesBefore}) {
          final time = slot.time.subtract(Duration(minutes: lead));
          if (!time.isAfter(now)) continue;
          result.add(PrayerReminder(1000 + day * 20 + slot.kind.index * 2 + (lead > 0 ? 1 : 0),
              slot.kind, time, lead));
        }
      }
    }
    result.sort((a,b) => a.time.compareTo(b.time));
    return result;
  }
}
