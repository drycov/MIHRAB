import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:mihrab/domain/ramadan.dart';
import 'package:mihrab/domain/hijri.dart';
import 'package:mihrab/domain/prayer_schedule.dart';
import 'package:mihrab/domain/schedule_repository.dart';

class Fixture implements ScheduleRepository {
  @override
  DailySchedule getDay(City city,DateTime day,{required bool hanafi}) =>
    DailySchedule(OfficialDayCodec.decode(city,day,{
      'fajr':'05:00','sunrise':'07:00','dhuhr':'12:00','asr':'15:00','maghrib':'18:00','isha':'20:00',
    }),ScheduleSource.dumkCache);
}
void main(){
  setUpAll(tz.initializeTimeZones);
  test('season includes only Ramadan days, starts on day one',(){
    for(final adjustment in [-2,0,2]){
      final days=RamadanCalendar.season(DateTime.utc(2026,11,24),adjustment:adjustment);
      expect(days.length,anyOf(29,30));
      expect(HijriCalendar.fromGregorian(days.first,adjustment:adjustment).day,1);
      expect(days.every((d)=>HijriCalendar.fromGregorian(d,adjustment:adjustment).month==9),isTrue);
    }
  });
  test('fasting boundaries use repository and switch at Fajr and Maghrib',(){
    final day=RamadanCalendar.forDay(Fixture(),City.all.first,DateTime.utc(2026,11,24),hanafi:true);
    expect(day.fastingDuration,const Duration(hours:13));
    expect(day.nextBoundary(day.fajr.subtract(const Duration(minutes:1)))?.time,day.fajr);
    expect(day.nextBoundary(day.fajr)?.time,day.maghrib);
    expect(day.nextBoundary(day.maghrib),isNull);
    expect(day.source,ScheduleSource.dumkCache);
  });
}
