import 'prayer_schedule.dart';

enum PrayerStatus {
  unmarked('Не отмечен'),
  onTime('Своевременно'),
  qada('Восполнен'),
  missed('Пропущен');

  const PrayerStatus(this.label);
  final String label;
  bool get completed => this == onTime || this == qada;
}

String diaryDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class DiaryDay {
  const DiaryDay(this.entries);
  final Map<PrayerKind, PrayerStatus> entries;
  PrayerStatus status(PrayerKind kind) =>
      entries[kind] ?? PrayerStatus.unmarked;
  int count(PrayerStatus status) =>
      PrayerKind.values
          .where((k) => k.obligatory && this.status(k) == status)
          .length;
  int get completed => count(PrayerStatus.onTime) + count(PrayerStatus.qada);
}
