import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/prayer_schedule.dart';
import '../domain/schedule_repository.dart';

class LocalScheduleRepository implements ScheduleRepository {
  LocalScheduleRepository(this.preferences);
  final SharedPreferences preferences;

  static String key(City city, int year) => 'dumk.v1.${city.latitude}.${city.longitude}.$year';
  static String dateKey(DateTime day) => '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  @override
  DailySchedule getDay(City city, DateTime day, {required bool hanafi}) {
    // Official Kazakhstan schedule is independent of the MWL Shafi option.
    if (hanafi) {
      try {
        final raw = preferences.getString(key(city, day.year));
        if (raw != null) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final row = data[dateKey(day)] as Map<String, dynamic>?;
          if (row != null) {
            return DailySchedule(OfficialDayCodec.decode(city, day, row), ScheduleSource.dumkCache);
          }
        }
      } on FormatException {
        // Invalid stored data must never be presented as official.
      } on TypeError {
        // Unexpected cache schema: use calculation.
      }
    }
    return DailySchedule(PrayerSchedule.forDay(city, day, hanafi: hanafi), ScheduleSource.astronomical);
  }

  // Only call with data normalized by a verified official API adapter.
  Future<void> storeValidatedYear(City city, int year, Map<String, dynamic> days) async {
    final expected = DateTime.utc(year + 1).difference(DateTime.utc(year)).inDays;
    if (days.length != expected) throw const FormatException('Incomplete year');
    for (var i = 0; i < expected; i++) {
      final day = DateTime(year, 1, i + 1);
      final row = days[dateKey(day)];
      if (row is! Map<String, dynamic>) throw const FormatException('Missing day');
      OfficialDayCodec.decode(city, day, row);
    }
    final saved = await preferences.setString(key(city, year), jsonEncode(days));
    if (!saved) throw StateError('Cache write failed');
  }
}
