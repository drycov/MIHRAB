import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:mihrab/domain/prayer_schedule.dart';
import 'package:mihrab/domain/schedule_repository.dart';
import 'package:mihrab/infrastructure/schedule_repository.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  test('missing cache explicitly falls back to calculation', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = LocalScheduleRepository(await SharedPreferences.getInstance());
    expect(repo.getDay(City.all.first, DateTime(2026,11,24), hanafi: true).source, ScheduleSource.astronomical);
  });
  test('invalid year rejected', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = LocalScheduleRepository(await SharedPreferences.getInstance());
    await expectLater(repo.storeValidatedYear(City.all.first, 2026, {}), throwsFormatException);
  });
  test('invalid times rejected', () {
    expect(() => OfficialDayCodec.decode(City.all.first, DateTime(2026,11,24), {'fajr':'25:00'}), throwsFormatException);
  });
}
