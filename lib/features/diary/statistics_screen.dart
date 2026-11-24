import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/prayer_diary.dart';
import '../../application/schedule.dart';
import '../../domain/prayer_diary.dart';
import '../../domain/prayer_schedule.dart';
import '../../domain/prayer_statistics.dart';
import '../../shared/format.dart';
import 'diary_screen.dart';

class StatisticsScreen extends ConsumerStatefulWidget{
  const StatisticsScreen({super.key});
  @override
  ConsumerState<StatisticsScreen> createState()=>_StatisticsScreenState();
}
class _StatisticsScreenState extends ConsumerState<StatisticsScreen>{
  int length=7;
  bool includeToday=false;
  @override
  Widget build(BuildContext context){
    final key=ref.watch(localDayProvider);
    final today=DateTime.utc(key.year,key.month,key.day);
    final end=includeToday?today:today.subtract(const Duration(days:1));
    final period=(end:end,length:length);
    final statistics=ref.watch(prayerStatisticsProvider(period));
    return Scaffold(appBar:AppBar(title:const Text('Статистика намазов')),
      body:SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[
        SegmentedButton<int>(segments:const [ButtonSegment(value:7,label:Text('7 дней')),ButtonSegment(value:30,label:Text('30 дней'))],selected:{length},onSelectionChanged:(v)=>setState(()=>length=v.single)),
        SwitchListTile(title:const Text('Включить сегодня'),value:includeToday,onChanged:(v)=>setState(()=>includeToday=v)),
        Text('${formatDate(end.subtract(Duration(days:length-1)))} — ${formatDate(end)}',textAlign:TextAlign.center),
        const SizedBox(height:12),
        ...statistics.when(
          loading:()=> <Widget>[const LinearProgressIndicator()],
          error:(_,__)=> <Widget>[const Text('Не удалось загрузить статистику'),TextButton(onPressed:()=>ref.invalidate(prayerStatisticsProvider(period)),child:const Text('Повторить'))],
          data:(s)=>_content(context,s)),
      ])));
  }
  List<Widget> _content(BuildContext context,PrayerStatistics s){
    final theme=Theme.of(context);
    final colors=theme.colorScheme;
    final palette=<PrayerStatus,Color>{PrayerStatus.onTime:colors.primary,PrayerStatus.qada:colors.tertiary,PrayerStatus.missed:colors.error,PrayerStatus.unmarked:colors.outline};
    return [
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Выполнено по отметкам: ${s.completed} / ${s.total}',style:theme.textTheme.titleLarge),
        const SizedBox(height:8),
        LinearProgressIndicator(value:s.completion),
        Text('${(s.completion*100).toStringAsFixed(1)}% от всех намазов периода'),
        Text('Отмечено: ${s.marked} / ${s.total}'),
        Text('Дней с пятью выполненными намазами: ${s.fullDays} / ${s.days.length}'),
        if(s.marked==0)const Text('За этот период пока нет записей.'),
      ]))),
      const SizedBox(height:16),
      Text('Распределение отметок',style:theme.textTheme.titleMedium),
      for(final status in PrayerStatus.values) ...[
        Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[Expanded(child:Text(status.label)),Text('${s.count(status)}')])),
        LinearProgressIndicator(value:s.count(status)/s.total,color:palette[status]),
      ],
      const SizedBox(height:20),
      Text('По намазам',style:theme.textTheme.titleMedium),
      for(final kind in PrayerKind.values.where((k)=>k.obligatory))Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${kind.label}: ${s.completedFor(kind)} / ${s.days.length}'),
        const SizedBox(height:8),
        Row(children:[for(final status in PrayerStatus.values)if(s.countFor(kind,status)>0)Expanded(flex:s.countFor(kind,status),child:Container(height:9,color:palette[status]))]),
        const SizedBox(height:8),
        Wrap(spacing:10,runSpacing:4,children:[for(final status in PrayerStatus.values)Text('${status.label}: ${s.countFor(kind,status)}',style:theme.textTheme.bodySmall)]),
      ]))),
      const SizedBox(height:16),
      Text('История по дням',style:theme.textTheme.titleMedium),
      for(final item in s.days.reversed)ListTile(
        title:Text(formatDate(item.date)),
        subtitle:Row(children:[for(final kind in PrayerKind.values.where((k)=>k.obligatory))Expanded(child:Tooltip(message:'${kind.label}: ${item.day.status(kind).label}',child:Container(margin:const EdgeInsets.only(right:3),height:8,color:palette[item.day.status(kind)])))]),
        trailing:Text('${item.day.completed}/5'),
        onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>DiaryScreen(initialDate:item.date))),
      ),
      const Text('Статистика основана только на личных отметках. Неотмеченные намазы не считаются пропущенными. Сегодня по умолчанию исключено, поскольку день ещё не завершён.'),
    ];
  }
}
