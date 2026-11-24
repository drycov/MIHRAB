import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/hijri.dart';

void main() {
  test('civil epoch and modern reference date', () {
    final epoch = HijriCalendar.fromGregorian(DateTime.utc(622, 7, 19));
    expect((epoch.year, epoch.month, epoch.day), (1, 1, 1));
    final date = HijriCalendar.fromGregorian(DateTime.utc(2024, 7, 8));
    expect((date.year, date.month, date.day), (1446, 1, 1));
  });
  test('adjustment is equivalent to shifting civil date', () {
    final a = HijriCalendar.fromGregorian(
      DateTime.utc(2026, 11, 24),
      adjustment: 2,
    );
    final b = HijriCalendar.fromGregorian(DateTime.utc(2026, 11, 26));
    expect(a.label, b.label);
    expect(
      () => HijriCalendar.fromGregorian(DateTime.utc(2026), adjustment: 3),
      throwsRangeError,
    );
  });
  test('all months have 29 or 30 days', () {
    for (var y = 1440; y < 1470; y++) {
      for (var m = 1; m <= 12; m++) {
        final end =
            m == 12
                ? HijriCalendar.start(y + 1, 1)
                : HijriCalendar.start(y, m + 1);
        expect(end - HijriCalendar.start(y, m), anyOf(29, 30));
      }
    }
  });
}
