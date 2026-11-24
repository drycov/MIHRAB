import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/settings.dart';
import '../../application/ramadan_reminder_preferences.dart';
import '../../application/reminder_coordinator.dart';
import '../../infrastructure/reminder_lock.dart';
import '../../domain/ramadan_reminders.dart';

class RamadanReminderScreen extends ConsumerStatefulWidget {
  const RamadanReminderScreen({super.key});
  @override
  ConsumerState<RamadanReminderScreen> createState()=>_RamadanReminderScreenState();
}
class _RamadanReminderScreenState extends ConsumerState<RamadanReminderScreen>{
  RamadanReminderSettings config=const RamadanReminderSettings();
  bool busy=false;
  String? status;
  @override
  void initState(){
    super.initState();
    try{config=RamadanReminderPreferences.read(ref.read(preferencesProvider));}
    catch(_){status='Настройки повреждены. Сохраните их повторно.';}
  }
  Future<void> save() async {
    setState((){busy=true;status=null;});
    try{
      final service=ref.read(notificationsProvider);
      final prefs=ref.read(preferencesProvider);
      final coordinator=ref.read(reminderCoordinatorProvider);
      if(config.enabled && !await service.requestPermission())throw StateError('Нет разрешения на уведомления');
      await ReminderLock.run(() async {
        await prefs.reload();
        await RamadanReminderPreferences.save(prefs,config);
      });
      final result=await coordinator.refresh();
      if(mounted)setState(()=>status=result);
    }catch(e){if(mounted)setState(()=>status=e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Widget lead(bool suhoor)=>DropdownButton<int>(isExpanded:true,value:suhoor?config.suhoorLead:config.iftarLead,
    items:[for(final m in RamadanReminderSettings.leads) DropdownMenuItem(value:m,child:Text(m==0?'В момент события':'За $m мин.'))],
    onChanged:busy?null:(v){if(v!=null)setState(()=>config=RamadanReminderSettings(suhoor:config.suhoor,iftar:config.iftar,
      suhoorLead:suhoor?v:config.suhoorLead,iftarLead:suhoor?config.iftarLead:v));});
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Напоминания Рамадана')),
    body:SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[
      SwitchListTile(title:const Text('Окончание сухура'),value:config.suhoor,onChanged:busy?null:(v)=>setState(()=>config=RamadanReminderSettings(suhoor:v,iftar:config.iftar,suhoorLead:config.suhoorLead,iftarLead:config.iftarLead))),
      if(config.suhoor)lead(true),
      SwitchListTile(title:const Text('Ифтар'),value:config.iftar,onChanged:busy?null:(v)=>setState(()=>config=RamadanReminderSettings(suhoor:config.suhoor,iftar:v,suhoorLead:config.suhoorLead,iftarLead:config.iftarLead))),
      if(config.iftar)lead(false),
      const Text('Уведомления планируются только на расчётные дни Рамадана, на шесть дней вперёд. Даты сверяйте с ДУМК. Используется системный звук. На iOS фонового пополнения расписания нет.'),
      FilledButton(onPressed:busy||!ref.watch(notificationsProvider).supported?null:save,child:const Text('Применить')),
      if(busy)const LinearProgressIndicator(),
      if(status!=null)Text(status!),
    ])));
}
