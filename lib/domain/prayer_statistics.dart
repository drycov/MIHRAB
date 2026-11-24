import 'prayer_diary.dart';
import 'prayer_schedule.dart';

class PrayerStatistics {
  PrayerStatistics(DateTime end, int length, Map<String, DiaryDay> records)
    : days = List.unmodifiable(_days(end, length, records));
  final List<({DateTime date, DiaryDay day})> days;
  static Iterable<({DateTime date, DiaryDay day})> _days(
    DateTime end,
    int length,
    Map<String, DiaryDay> records,
  ) sync* {
    if (length < 1 || length > 366) throw RangeError.range(length, 1, 366);
    final last = DateTime.utc(end.year, end.month, end.day);
    for (var i = length - 1; i >= 0; i--) {
      final date = last.subtract(Duration(days: i));
      yield (date: date, day: records[diaryDate(date)] ?? const DiaryDay({}));
    }
  }

  int get total => days.length * 5;
  int count(PrayerStatus status) =>
      days.fold(0, (sum, d) => sum + d.day.count(status));
  int get completed => count(PrayerStatus.onTime) + count(PrayerStatus.qada);
  int get marked => total - count(PrayerStatus.unmarked);
  double get completion => completed / total;
  int countFor(PrayerKind kind, PrayerStatus status) {
    if (!kind.obligatory) throw ArgumentError('Only obligatory prayers');
    return days.where((d) => d.day.status(kind) == status).length;
  }

  int completedFor(PrayerKind kind) =>
      countFor(kind, PrayerStatus.onTime) + countFor(kind, PrayerStatus.qada);
  int get fullDays => days.where((d) => d.day.completed == 5).length;
}
