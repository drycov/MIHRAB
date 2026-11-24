import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/prayer_diary.dart';
import 'package:mihrab/domain/prayer_schedule.dart';
void main(){
  test('unmarked prayers are distinct from missed',(){
    const day=DiaryDay({PrayerKind.fajr:PrayerStatus.onTime,PrayerKind.dhuhr:PrayerStatus.qada,PrayerKind.asr:PrayerStatus.missed});
    expect(day.completed,2);
    expect(day.count(PrayerStatus.missed),1);
    expect(day.count(PrayerStatus.unmarked),2);
  });
  test('date keys preserve civil dates',(){
    expect(diaryDate(DateTime.utc(2026,1,2)),'2026-01-02');
  });
  test('sunrise is excluded',(){
    const day=DiaryDay({PrayerKind.sunrise:PrayerStatus.onTime});
    expect(day.completed,0);
    expect(day.count(PrayerStatus.unmarked),5);
  });
}
