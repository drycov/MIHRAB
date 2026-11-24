import 'package:timezone/timezone.dart' as tz;
import 'prayer_schedule.dart';

enum ScheduleSource { dumkCache, astronomical }

class DailySchedule {
  const DailySchedule(this.slots, this.source);
  final List<PrayerSlot> slots;
  final ScheduleSource source;
}

abstract interface class ScheduleRepository {
  DailySchedule getDay(City city, DateTime day, {required bool hanafi});
}

abstract final class OfficialDayCodec {
  static List<PrayerSlot> decode(City city, DateTime day, Map<String, dynamic> row) {
    final zone = tz.getLocation(city.zone);
    final slots = <PrayerSlot>[];
    for (final kind in PrayerKind.values) {
      final value = row[kind.name];
      if (value is! String || !RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value)) {
        throw FormatException('Invalid time for ${kind.name}');
      }
      final parts = value.split(':').map(int.parse).toList();
      final time = tz.TZDateTime(zone, day.year, day.month, day.day, parts[0], parts[1]);
      if (slots.isNotEmpty && !time.isAfter(slots.last.time)) {
        throw const FormatException('Non-monotonic prayer schedule');
      }
      slots.add(PrayerSlot(kind, time));
    }
    return List.unmodifiable(slots);
  }
}
