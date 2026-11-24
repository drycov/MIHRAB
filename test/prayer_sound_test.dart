import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/prayer_sound.dart';
import 'package:mihrab/domain/prayer_schedule.dart';
import 'package:mihrab/application/reminder_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('channel identity separates prayer, profile and reminder type', () {
    final ids = {
      for (final p in PrayerKind.values.where((p) => p.obligatory))
        for (final sound in PrayerSound.values)
          for (final early in [false, true])
            PrayerSoundChannels.id(p, sound, early: early),
    };
    expect(ids.length, 40);
  });
  test('sound preferences round trip and legacy defaults', () async {
    SharedPreferences.setMockInitialValues({
      'reminder_prayers': ['fajr'],
    });
    final prefs = await SharedPreferences.getInstance();
    expect(ReminderPreferences.read(prefs)!.sounds, isEmpty);
    await ReminderPreferences(
      enabled: {PrayerKind.fajr},
      lead: 15,
      exact: false,
      sounds: {PrayerKind.fajr: PrayerSound.silent},
    ).save(prefs);
    expect(
      ReminderPreferences.read(prefs)!.sounds[PrayerKind.fajr],
      PrayerSound.silent,
    );
    expect(PrayerSound.parse('unknown'), PrayerSound.system);
  });
}
