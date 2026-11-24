import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:mihrab/domain/prayer_schedule.dart';
import 'package:mihrab/domain/schedule_repository.dart';
import 'package:mihrab/domain/reminders.dart';

class FixtureRepository implements ScheduleRepository {
  @override
  DailySchedule getDay(City city, DateTime day, {required bool hanafi}) =>
      DailySchedule(
        OfficialDayCodec.decode(city, day, {
          'fajr': '05:00',
          'sunrise': '07:00',
          'dhuhr': '12:00',
          'asr': '15:00',
          'maghrib': '17:00',
          'isha': '19:00',
        }),
        ScheduleSource.dumkCache,
      );
}

void main() {
  setUpAll(tz.initializeTimeZones);
  test(
    'reminders use injected schedule rather than astronomical calculation',
    () {
      final repo = FixtureRepository();
      final reminders = ReminderPlanner.plan(
        City.all.first,
        DateTime.utc(2026, 11, 24),
        hanafi: true,
        enabled: {PrayerKind.dhuhr},
        minutesBefore: 15,
        repository: repo,
      );
      expect(reminders, isNotEmpty);
      expect(reminders.first.time.hour, 11);
      expect(reminders.first.time.minute, 45);
      expect(reminders[1].time.hour, 12);
      expect(reminders[1].time.minute, 0);
    },
  );
}
