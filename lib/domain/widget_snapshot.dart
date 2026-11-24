import 'prayer_schedule.dart';
import 'schedule_repository.dart';
import 'hijri.dart';
import '../l10n/mihrab_strings.dart';

abstract final class WidgetSnapshot {
  static Map<String,dynamic> build(City city, DateTime day, ScheduleRepository repository,
      {required bool hanafi, required int adjustment, required DateTime now, int? completed, String language='ru'}){
    String tr(String value)=>translateMihrab(language,value);
    final days=<Map<String,dynamic>>[];
    for(var i=0;i<7;i++){
      final date=DateTime.utc(day.year,day.month,day.day+i);
      final schedule=repository.getDay(city,date,hanafi:hanafi);
      final hijri=HijriCalendar.fromGregorian(date,adjustment:adjustment);
      days.add({'date':'${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}',
        'hijri':'${hijri.day} ${tr(HijriDate.months[hijri.month-1])} ${hijri.year} ${tr("г.х.")}',
        'prayers':[for(final slot in schedule.slots.where((s)=>s.kind.obligatory))
          {'name':tr(slot.kind.label),'epoch':slot.time.millisecondsSinceEpoch}],
        'source':schedule.source==ScheduleSource.dumkCache?'ДУМК':'MWL',
        if(i==0&&completed!=null)'completed':completed.clamp(0,5)});
    }
    return {'version':1,'city':tr(city.name),'language':language,'labels':{'open':tr('Откройте приложение'),'refresh':tr('Обновите расписание'),'next':tr('Следующий'),'tomorrow':tr('Завтра'),'diary':tr('Дневник'),'openMihrab':tr('Откройте MIHRAB'),'refreshHint':tr('Для обновления расписания'),'stale':tr('Откройте приложение для обновления')},'zone':city.zone,'generated':now.millisecondsSinceEpoch,'days':days};
  }
}
