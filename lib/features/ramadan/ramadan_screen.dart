import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/clock.dart';
import '../../application/hijri_settings.dart';
import '../../application/schedule.dart';
import '../../application/settings.dart';
import '../../domain/ramadan.dart';
import '../../domain/schedule_repository.dart';
import '../../shared/format.dart';

final ramadanSeasonProvider = Provider.autoDispose<List<RamadanDay>>((ref) {
  final key = ref.watch(localDayProvider);
  final adjustment = ref.watch(hijriAdjustmentProvider);
  final repository = ref.watch(scheduleRepositoryProvider);
  final city = ref.watch(settingsProvider.select((s) => s.city));
  final dates = RamadanCalendar.season(DateTime(key.year,key.month,key.day), adjustment: adjustment);
  return dates.map((date) => RamadanCalendar.forDay(repository,city,date,
    hanafi:key.hanafi,adjustment:adjustment)).toList(growable:false);
});

class RamadanScreen extends ConsumerWidget {
  const RamadanScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(ramadanSeasonProvider);
    final key = ref.watch(localDayProvider);
    final today = DateTime.utc(key.year,key.month,key.day);
    final city = ref.watch(settingsProvider.select((s) => s.city));
    final current = days.where((d) => d.date == today).firstOrNull;
    final theme = Theme.of(context);
    return Scaffold(appBar:AppBar(title:const Text('Рамадан')),
      body: ListView(padding:const EdgeInsets.all(16),children:[
        Text(city.name,style:theme.textTheme.titleMedium),
        Text('Рамадан ${days.first.hijri.year} г.х.',style:theme.textTheme.headlineSmall),
        Text('${formatDate(days.first.date)} — ${formatDate(days.last.date)}'),
        const SizedBox(height:16),
        if(current != null) ...[
          Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('День ${current.hijri.day} из ${days.length}',style:theme.textTheme.titleLarge),
              LinearProgressIndicator(value:current.hijri.day/days.length),
              const SizedBox(height:16),
              FastingCountdown(day:current),
            ]))),
        ] else Card(child:ListTile(title:const Text('До расчётного начала Рамадана'),
          subtitle:Text('${days.first.date.difference(today).inDays} дней'))),
        const SizedBox(height:12),
        const Text('Сухур завершается к Фаджру; ифтар начинается с Магриба. Даты предварительные, сверяйте с ДУМК.'),
        const SizedBox(height:12),
        Row(children:[
          const Expanded(flex:2,child:Text('Дата')),
          const Expanded(child:Text('Фаджр')),
          const Expanded(child:Text('Ифтар')),
          const Expanded(child:Text('Пост')),
        ]),
        for(final day in days) Card(color:day.date==today?theme.colorScheme.primaryContainer:null,
          child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[
            Expanded(flex:2,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(formatDate(day.date)),Text('День ${day.hijri.day} · ${day.source==ScheduleSource.dumkCache?"ДУМК":"MWL"}',style:theme.textTheme.labelSmall),
            ])),
            Expanded(child:Text(formatTime(day.fajr))),
            Expanded(child:Text(formatTime(day.maghrib))),
            Expanded(child:Text('${day.fastingDuration.inHours}:${two(day.fastingDuration.inMinutes.remainder(60))}')),
          ]))),
      ]));
  }
}

class FastingCountdown extends ConsumerWidget {
  const FastingCountdown({super.key,required this.day});
  final RamadanDay day;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now=ref.watch(clockProvider);
    final next=day.nextBoundary(now);
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(next?.label ?? 'Ифтар наступил'),
      if(next!=null) Text(formatRemaining(next.time.difference(now)),style:Theme.of(context).textTheme.headlineMedium),
      Text('Фаджр: ${formatTime(day.fajr)} · Ифтар: ${formatTime(day.maghrib)}'),
    ]);
  }
}
