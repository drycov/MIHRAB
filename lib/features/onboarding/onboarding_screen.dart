import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/onboarding.dart';
import '../../application/settings.dart';
import '../../application/reminder_coordinator.dart';
import '../../application/reminder_preferences.dart';
import '../../domain/prayer_schedule.dart';
import '../../domain/prayer_sound.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key,this.revisit=false});
  final bool revisit;
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int step=0;
  late int city;
  late bool hanafi, light;
  bool notifications=false;
  bool exact=false;
  bool busy=false;
  PrayerSound sound=PrayerSound.system;
  String? message;
  @override
  void initState(){
    super.initState();
    final settings=ref.read(settingsProvider);
    city=settings.cityIndex; hanafi=settings.hanafi; light=settings.light;
  }
  Future<void> finish({bool skipNotifications=false}) async {
    if(busy)return;
    setState(() {busy=true;message=null;});
    try {
      final controller=ref.read(settingsProvider.notifier);
      final coordinator=ref.read(reminderCoordinatorProvider);
      final onboarding=ref.read(onboardingProvider.notifier);
      final prefs=ref.read(preferencesProvider);
      await controller.city(city);
      await controller.hanafi(hanafi);
      await controller.light(light);
      if(notifications && !skipNotifications){
        final enabled=PrayerKind.values.where((p)=>p.obligatory).toSet();
        final existing=ReminderPreferences.read(prefs);
        await coordinator.apply(enabled,existing?.lead ?? 0,exact,
          sounds:{for(final p in enabled) p:sound});
      }
      await onboarding.complete();
      if(mounted && widget.revisit) Navigator.of(context).pop();
    } catch (_) {
      if(mounted)setState(()=>message='Не удалось завершить настройку. Проверьте разрешения или продолжите без настройки уведомлений.');
    } finally {
      if(mounted)setState(()=>busy=false);
    }
  }

  @override
  Widget build(BuildContext context){
    final service=ref.watch(notificationsProvider);
    final theme=Theme.of(context);
    return Scaffold(
      appBar:AppBar(title:const Text('MIHRAB')),
      body:SafeArea(child:Column(children:[
        LinearProgressIndicator(value:(step+1)/3),
        Expanded(child:ListView(padding:const EdgeInsets.all(24),children:[
          Text('Шаг ${step+1} из 3',style:theme.textTheme.labelLarge),
          const SizedBox(height:24),
          if(step==0)...[
            const Icon(Icons.mosque_outlined,size:80),
            const SizedBox(height:20),
            Text('Добро пожаловать в MIHRAB',style:theme.textTheme.headlineMedium),
            const Text('Время намазов, направление Киблы, исламский календарь и напоминания в одном приложении.'),
            const SizedBox(height:16),
            const Text('Расчётное расписание следует сверять с официальными данными ДУМК.'),
          ],
          if(step==1)...[
            Text('Ваш город и настройки',style:theme.textTheme.headlineMedium),
            const SizedBox(height:16),
            DropdownButton<int>(isExpanded:true,value:city,
              items:[for(var i=0;i<City.all.length;i++) DropdownMenuItem(value:i,child:Text(City.all[i].name))],
              onChanged:busy?null:(v){if(v!=null)setState(()=>city=v);}),
            SwitchListTile(title:const Text('Ханафитский Аср'),subtitle:const Text('Метод определения времени Асра'),value:hanafi,onChanged:busy?null:(v)=>setState(()=>hanafi=v)),
            SwitchListTile(title:const Text('Светлая тема'),value:light,onChanged:busy?null:(v)=>setState(()=>light=v)),
          ],
          if(step==2)...[
            Text('Напоминания',style:theme.textTheme.headlineMedium),
            const SizedBox(height:12),
            if(!service.supported) const Text('На этой платформе системные уведомления недоступны.'),
            SwitchListTile(title:const Text('Напоминать о пяти намазах'),value:notifications,onChanged:busy||!service.supported?null:(v)=>setState(()=>notifications=v)),
            if(notifications)...[
              if(service.isAndroid) SwitchListTile(title:const Text('Точные уведомления'),subtitle:const Text('Android может запросить дополнительное разрешение'),value:exact,onChanged:busy?null:(v)=>setState(()=>exact=v)),
              DropdownButton<PrayerSound>(isExpanded:true,value:sound,
                items:[for(final s in [PrayerSound.system,if(service.isAndroid) PrayerSound.vibration,PrayerSound.silent]) DropdownMenuItem(value:s,child:Text(s.label))],
                onChanged:busy?null:(v){if(v!=null)setState(()=>sound=v);}),
              const Text('Разрешение будет запрошено только после завершения настройки. Записи азана можно добавить позже.'),
            ],
            const Text('Если пропустить уведомления, существующие настройки не изменятся.'),
          ],
          if(message!=null) Text(message!,style:TextStyle(color:theme.colorScheme.error)),
        ])),
        Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          if(busy) const LinearProgressIndicator(),
          FilledButton(onPressed:busy?null:step<2?()=>setState(()=>step++):()=>finish(),
            child:Text(step<2?'Далее':'Завершить')),
          if(step>0) TextButton(onPressed:busy?null:()=>setState(() {step--;message=null;}),child:const Text('Назад')),
          if(step==2 && notifications) TextButton(onPressed:busy?null:()=>finish(skipNotifications:true),child:const Text('Продолжить без настройки уведомлений')),
        ])),
      ])),
    );
  }
}
