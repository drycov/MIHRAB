import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:mihrab/application/reminder_preferences.dart';
import 'package:mihrab/domain/reminders.dart';
import 'package:mihrab/domain/prayer_schedule.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  test('overlapping rolling windows preserve notification identities', () {
    List<PrayerReminder> plan(int day) => ReminderPlanner.plan(
      City.all.first,
      DateTime.utc(2026, 11, day),
      hanafi: true,
      enabled: {PrayerKind.dhuhr},
      minutesBefore: 15,
    );
    final first = {for (final p in plan(24)) p.time: p.id};
    final second = plan(25);
    final overlap = second.where((p) => first.containsKey(p.time)).toList();
    expect(overlap, isNotEmpty);
    for (final p in overlap) {
      expect(p.id, first[p.time]);
      expect(ReminderPlanner.ownsId(p.id), isTrue);
    }
    expect(ReminderPlanner.ownsId(1000), isTrue);
    expect(ReminderPlanner.ownsId(42), isFalse);
  });
  test('legacy settings migrate to one versioned value', () async {
    SharedPreferences.setMockInitialValues({
      'reminder_prayers': ['fajr', 'sunrise'],
      'reminder_lead': 15,
      'reminder_exact': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final config = ReminderPreferences.read(prefs)!;
    expect(config.enabled, {PrayerKind.fajr});
    await config.save(prefs);
    await prefs.setInt('reminder_lead', 30);
    expect(ReminderPreferences.read(prefs)!.lead, 15);
    expect(ReminderPreferences.read(prefs)!.exact, isTrue);
  });
}
