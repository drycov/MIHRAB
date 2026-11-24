import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/prayer_diary.dart';
import '../../application/schedule.dart';
import '../../domain/prayer_diary.dart';
import '../../domain/prayer_schedule.dart';
import '../../shared/format.dart';
import 'statistics_screen.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key,this.initialDate});
  final DateTime? initialDate;
  @override
  ConsumerState<DiaryScreen> createState()=>_DiaryScreenState();
}
class _DiaryScreenState extends ConsumerState<DiaryScreen>{
  DateTime? selected;
  bool busy=false;
  @override
  void initState(){super.initState();selected=widget.initialDate;}
  Future<void> mark(DateTime date,PrayerKind kind,PrayerStatus status)async{
    if(busy)return;
    setState(()=>busy=true);
    try{
      await ref.read(diaryRepositoryProvider).mark(date,kind,status);
      if(mounted){ref.invalidate(diaryDayProvider(date));ref.invalidate(prayerStatisticsProvider);}
    }catch(_){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Не удалось сохранить запись')));
    }finally{if(mounted)setState(()=>busy=false);}
  }
  @override
  Widget build(BuildContext context){
    final key=ref.watch(localDayProvider);
    final today=DateTime.utc(key.year,key.month,key.day);
    final date=selected==null||selected!.isAfter(today)?today:selected!;
    final supported=!kIsWeb&&(defaultTargetPlatform==TargetPlatform.android||defaultTargetPlatform==TargetPlatform.iOS||defaultTargetPlatform==TargetPlatform.macOS);
    if(!supported)return Scaffold(appBar:AppBar(title:const Text('Дневник намазов')),body:const Center(child:Text('Локальный дневник недоступен на этой платформе')));
    final day=ref.watch(diaryDayProvider(date));
    return Scaffold(appBar:AppBar(title:const Text('Дневник намазов'),actions:[IconButton(tooltip:'Статистика',icon:const Icon(Icons.bar_chart),onPressed:busy?null:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const StatisticsScreen())))]),
      body:SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          IconButton(tooltip:'Предыдущий день',onPressed:busy||!date.isAfter(DateTime.utc(2000))?null:()=>setState(()=>selected=date.subtract(const Duration(days:1))),icon:const Icon(Icons.chevron_left)),
          TextButton.icon(icon:const Icon(Icons.calendar_today),label:Text(formatDate(date)),onPressed:busy?null:()async{
            final result=await showDatePicker(context:context,initialDate:DateTime(date.year,date.month,date.day),firstDate:DateTime(2000),lastDate:DateTime(today.year,today.month,today.day));
            if(result!=null&&mounted)setState(()=>selected=DateTime.utc(result.year,result.month,result.day));
          }),
          IconButton(tooltip:'Следующий день',onPressed:busy||!date.isBefore(today)?null:()=>setState(()=>selected=date.add(const Duration(days:1))),icon:const Icon(Icons.chevron_right)),
        ]),
        if(date!=today)TextButton(onPressed:busy?null:()=>setState(()=>selected=null),child:const Text('Сегодня')),
        ...day.when(
          loading:()=> <Widget>[const LinearProgressIndicator()],
          error:(e,s)=> <Widget>[const Text('Не удалось открыть дневник'),TextButton(onPressed:()=>ref.invalidate(diaryDayProvider(date)),child:const Text('Повторить'))],
          data:(value)=> <Widget>[
            Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('Выполнено ${value.completed} из 5',style:Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height:12),LinearProgressIndicator(value:value.completed/5),
              const SizedBox(height:12),
              Text('Своевременно: ${value.count(PrayerStatus.onTime)} · Восполнено: ${value.count(PrayerStatus.qada)}'),
              Text('Пропущено: ${value.count(PrayerStatus.missed)} · Не отмечено: ${value.count(PrayerStatus.unmarked)}'),
            ]))),
            for(final kind in PrayerKind.values.where((k)=>k.obligatory))
              Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text('${kind.label} · ${kind.arabic}',style:Theme.of(context).textTheme.titleMedium),
                DropdownButton<PrayerStatus>(isExpanded:true,value:value.status(kind),items:[for(final status in PrayerStatus.values)DropdownMenuItem(value:status,child:Text(status.label))],
                  onChanged:busy?null:(status){if(status!=null)mark(date,kind,status);}),
              ]))),
          ]),
        if(busy)const LinearProgressIndicator(),
        const SizedBox(height:12),
        const Text('Отметки личные и задаются вручную. Неотмеченный намаз не считается пропущенным. Записи привязаны к выбранной календарной дате и не изменяются при смене города.'),
      ])));
  }
}
