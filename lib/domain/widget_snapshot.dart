import 'prayer_schedule.dart';
import 'schedule_repository.dart';
import 'hijri.dart';

abstract final class WidgetSnapshot {
  static Map<String,dynamic> build(City city, DateTime day, ScheduleRepository repository,
      {required bool hanafi, required int adjustment, required DateTime now, int? completed}){
    final days=<Map<String,dynamic>>[];
    for(var i=0;i<7;i++){
      final date=DateTime.utc(day.year,day.month,day.day+i);
      final schedule=repository.getDay(city,date,hanafi:hanafi);
      days.add({'date':'${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}',
        'hijri':HijriCalendar.fromGregorian(date,adjustment:adjustment).label,
        'prayers':[for(final slot in schedule.slots.where((s)=>s.kind.obligatory))
          {'name':slot.kind.label,'epoch':slot.time.millisecondsSinceEpoch}],
        'source':schedule.source==ScheduleSource.dumkCache?'ДУМК':'MWL',
        if(i==0&&completed!=null)'completed':completed.clamp(0,5)});
    }
    return {'version':1,'city':city.name,'zone':city.zone,'generated':now.millisecondsSinceEpoch,'days':days};
  }
}
