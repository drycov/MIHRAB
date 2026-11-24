import 'package:timezone/timezone.dart' as tz;
import 'hijri.dart';
import 'prayer_schedule.dart';
import 'reminders.dart';
import 'schedule_repository.dart';

class RamadanReminderSettings {
  const RamadanReminderSettings({this.suhoor=false,this.iftar=false,this.suhoorLead=30,this.iftarLead=10});
  final bool suhoor, iftar;
  final int suhoorLead, iftarLead;
  bool get enabled => suhoor || iftar;
  static const leads = [0,5,10,15,30,45,60];
  static int validLead(Object? value,int fallback) => leads.contains(value) ? value as int : fallback;
}

abstract final class RamadanReminderPlanner {
  static const base=200000000;
  static const limit=300000000;
  static bool ownsId(int id)=>id>=base && id<limit;
  static List<PrayerReminder> plan(City city, DateTime now, {required bool hanafi,
    required RamadanReminderSettings config, required int adjustment, required ScheduleRepository repository}) {
    if(!config.enabled)return [];
    final local=tz.TZDateTime.from(now,tz.getLocation(city.zone));
    final result=<PrayerReminder>[];
    for(var i=0;i<6;i++){
      final date=DateTime(local.year,local.month,local.day+i);
      if(HijriCalendar.fromGregorian(date,adjustment:adjustment).month!=9)continue;
      final slots=repository.getDay(city,date,hanafi:hanafi).slots;
      final day=DateTime.utc(date.year,date.month,date.day).difference(DateTime.utc(2000)).inDays;
      for(final kind in [PrayerKind.fajr,PrayerKind.maghrib]){
        final suhoor=kind==PrayerKind.fajr;
        if(suhoor ? !config.suhoor : !config.iftar)continue;
        final lead=suhoor?config.suhoorLead:config.iftarLead;
        final time=slots.firstWhere((p)=>p.kind==kind).time.subtract(Duration(minutes:lead));
        if(!time.isAfter(now))continue;
        final id=base+day*2+(suhoor?0:1);
        if(!ownsId(id))throw RangeError('Unsupported Ramadan date');
        result.add(PrayerReminder(id,kind,time,lead,ramadan:true));
      }
    }
    return result;
  }
}
