import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:mihrab/domain/prayer_schedule.dart';
import 'package:mihrab/domain/reminders.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  test('only future obligatory reminders, unique ids, at most 60', () {
    final now = DateTime.utc(2026, 11, 24, 9);
    final plan = ReminderPlanner.plan(
      City.all.first,
      now,
      hanafi: true,
      enabled: PrayerKind.values.toSet(),
      minutesBefore: 15,
    );
    expect(plan, isNotEmpty);
    expect(plan.length, lessThanOrEqualTo(60));
    expect(plan.map((p) => p.id).toSet().length, plan.length);
    expect(plan.every((p) => p.kind.obligatory && p.time.isAfter(now)), isTrue);
  });
  test('disabled reminders yield empty plan', () {
    expect(
      ReminderPlanner.plan(
        City.all.first,
        DateTime.utc(2026, 11, 24),
        hanafi: true,
        enabled: {},
        minutesBefore: 0,
      ),
      isEmpty,
    );
  });
}
