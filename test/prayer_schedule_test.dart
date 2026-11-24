import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/prayer_schedule.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);
  test('six ordered events in Kazakhstan local time', () {
    final slots = PrayerSchedule.forDay(City.all.first, DateTime(2026, 11, 24));
    expect(slots.length, 6);
    expect(slots.first.time.timeZoneOffset, const Duration(hours: 5));
    for (var i = 1; i < slots.length; i++) {
      expect(slots[i].time.isAfter(slots[i - 1].time), isTrue);
    }
  });
  test('after Isha next prayer is tomorrow Fajr', () {
    final city = City.all.first;
    final isha = PrayerSchedule.forDay(city, DateTime(2026, 11, 24)).last;
    final next = PrayerSchedule.next(city, isha.time.add(const Duration(minutes: 1)));
    expect(next.kind, PrayerKind.fajr);
    expect(next.time.day, 25);
  });
  test('Hanafi Asr is later than Shafi Asr', () {
    final city = City.all.first;
    final day = DateTime(2026, 11, 24);
    expect(PrayerSchedule.forDay(city, day)[3].time.isAfter(
      PrayerSchedule.forDay(city, day, hanafi: false)[3].time), isTrue);
  });
}
