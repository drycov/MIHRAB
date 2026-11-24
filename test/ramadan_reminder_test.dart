import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/ramadan_reminders.dart';
import 'package:mihrab/domain/reminders.dart';
import 'package:mihrab/domain/prayer_schedule.dart';

void main() {
  test('Ramadan IDs are owned but separate from prayer IDs', () {
    expect(ReminderPlanner.ownsId(RamadanReminderPlanner.base), isTrue);
    expect(
      RamadanReminderPlanner.ownsId(
        ReminderPlanner.stableId(
          DateTime(2026, 11, 24),
          PrayerKind.fajr,
          false,
        ),
      ),
      isFalse,
    );
  });
  test('lead validation and opt-in defaults', () {
    expect(const RamadanReminderSettings().enabled, isFalse);
    expect(RamadanReminderSettings.validLead(999, 30), 30);
    expect(RamadanReminderSettings.validLead(45, 30), 45);
  });
}
