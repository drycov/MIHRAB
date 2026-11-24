import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/prayer_diary.dart';
import 'package:mihrab/domain/prayer_schedule.dart';
import 'package:mihrab/domain/prayer_statistics.dart';

void main() {
  test('empty dates count as unmarked, never missed', () {
    final stats = PrayerStatistics(DateTime.utc(2026, 1, 2), 7, {});
    expect(stats.total, 35);
    expect(stats.count(PrayerStatus.unmarked), 35);
    expect(stats.count(PrayerStatus.missed), 0);
    expect(stats.completion, 0);
    expect(stats.days.first.date, DateTime.utc(2025, 12, 27));
  });
  test('counts statuses and individual prayers', () {
    final stats = PrayerStatistics(DateTime.utc(2026, 1, 2), 2, {
      '2026-01-01': const DiaryDay({
        PrayerKind.fajr: PrayerStatus.onTime,
        PrayerKind.asr: PrayerStatus.qada,
        PrayerKind.isha: PrayerStatus.missed,
      }),
    });
    expect(stats.completed, 2);
    expect(stats.marked, 3);
    expect(stats.completion, 0.2);
    expect(stats.count(PrayerStatus.unmarked), 7);
    expect(stats.completedFor(PrayerKind.asr), 1);
    expect(stats.countFor(PrayerKind.fajr, PrayerStatus.unmarked), 1);
  });
  test(
    'invalid period rejected',
    () => expect(
      () => PrayerStatistics(DateTime.utc(2026), 0, {}),
      throwsRangeError,
    ),
  );
}
