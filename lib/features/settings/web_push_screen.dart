import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';
import '../../application/settings.dart';
import '../../application/schedule.dart';
import '../../domain/prayer_schedule.dart';
import '../../domain/reminders.dart';
import '../../infrastructure/web_push_bridge.dart';
import '../../l10n/mihrab_strings.dart';

class WebPushScreen extends ConsumerStatefulWidget {
  const WebPushScreen({super.key});
  @override
  ConsumerState<WebPushScreen> createState() => _WebPushScreenState();
}
class _WebPushScreenState extends ConsumerState<WebPushScreen> {
  final enabled = PrayerKind.values.where((p)=>p.obligatory).toSet();
  int lead = 0;
  bool consent = false, busy = false;
  Map<String,dynamic> status = const {};
  @override
  void initState() {
    super.initState();
    status = pushStatus();
    final prefs = ref.read(preferencesProvider);
    final saved = prefs.getStringList('web_push_prayers_v1');
    if (saved != null) {
      enabled.retainWhere((p)=>saved.contains(p.name));
    }
    final value = prefs.getInt('web_push_lead_v1');
    if ([0,5,10,15,30].contains(value)) lead = value!;
  }
  String schedule() {
    final s = ref.read(settingsProvider);
    return jsonEncode(ReminderPlanner.plan(s.city,DateTime.now(),
      hanafi:s.hanafi,enabled:enabled,minutesBefore:lead,
      repository:ref.read(scheduleRepositoryProvider)).map((r)=> {
        'id':r.id,'kind':r.kind.name,'dueAt':r.time.millisecondsSinceEpoch,'lead':r.minutesBefore
      }).toList());
  }
  Future<void> operate(String action) async {
    setState(()=>busy=true);
    var result = 'error';
    try {
      if (action=='remove') {
        result=await unsubscribePush();
      } else {
        final rows=schedule();
        final locale=Localizations.localeOf(context).languageCode;
        result=action=='subscribe' ? await subscribePush(locale,rows) : await syncPush(rows);
        if(result=='ok') {
          final prefs=ref.read(preferencesProvider);
          await prefs.setStringList('web_push_prayers_v1',enabled.map((p)=>p.name).toList());
          await prefs.setInt('web_push_lead_v1',lead);
        }
      }
    } catch (_) {}
    if(!mounted) return;
    setState(() {busy=false;status=pushStatus();});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(context.tr(result=='ok'?'Операция выполнена':'Не удалось выполнить Web Push'))));
  }
  @override
  Widget build(BuildContext context) {
    final active=status['subscribed']==true;
    final ready=status['configured']==true && status['supported']==true;
    final until=status['until'];
    return Scaffold(
      appBar:AppBar(title:const Text('Web Push')),
      body:ListView(padding:const EdgeInsets.all(MihrabTokens.space),children:[
        IslamicCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(context.tr(!ready?'Web Push недоступен':active?'Подписка сохранена':'Подписка отсутствует'),style:Theme.of(context).textTheme.titleMedium),
          const SizedBox(height:MihrabTokens.spaceSm),
          Text(context.tr('Расписание действует до шести суток. Обновляйте его вручную после смены города или настроек.')),
          if(until is int && until>0) Text(DateTime.fromMillisecondsSinceEpoch(until).toLocal().toString()),
          if(!active) CheckboxListTile(value:consent,onChanged:busy||!ready?null:(v)=>setState(()=>consent=v??false),title:Text(context.tr('Разрешаю передачу подписки браузера и времени напоминаний на сервер.'))),
        ])),
        IslamicSectionTitle(context.tr('Напоминания')),
        IslamicCard(padding:EdgeInsets.zero,child:Column(children:[
          for(final p in PrayerKind.values.where((p)=>p.obligatory))
            CheckboxListTile(value:enabled.contains(p),onChanged:busy?null:(v)=>setState(()=>v==true?enabled.add(p):enabled.remove(p)),title:Text(context.tr(p.label))),
          ListTile(title:Text(context.tr('Предварительное напоминание')),trailing:DropdownButton<int>(value:lead,items:[for(final n in [0,5,10,15,30]) DropdownMenuItem(value:n,child:Text('$n'))],onChanged:busy?null:(v)=>setState(()=>lead=v??0))),
        ])),
        const SizedBox(height:MihrabTokens.space),
        FilledButton(onPressed:busy||!ready||(!active&&!consent)?null:()=>operate(active?'sync':'subscribe'),child:Text(context.tr(active?'Синхронизировать расписание':'Подписаться на Web Push'))),
        if(active) OutlinedButton(onPressed:busy?null:()=>operate('remove'),child:Text(context.tr('Отписаться от Web Push'))),
      ]),
    );
  }
}
