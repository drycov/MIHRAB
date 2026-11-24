import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/hijri_settings.dart';
import '../../application/schedule.dart';
import '../../domain/hijri.dart';
import '../../shared/format.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  int offset = 0;
  DateTime? selected;
  static const months = ['Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'];
  @override
  Widget build(BuildContext context) {
    final key = ref.watch(localDayProvider);
    final adjustment = ref.watch(hijriAdjustmentProvider);
    final today = DateTime(key.year,key.month,key.day);
    final month = DateTime(today.year,today.month + offset);
    final length = DateTime(month.year,month.month + 1,0).day;
    final first = month.weekday - 1;
    final day = selected ?? (offset == 0 ? today : month);
    final hijri = HijriCalendar.fromGregorian(day, adjustment: adjustment);
    final schedule = ref.watch(dailyScheduleProvider((city:key.city,hanafi:key.hanafi,year:day.year,month:day.month,day:day.day)));
    return ListView(padding: const EdgeInsets.all(16),children: [
      Text(HijriCalendar.fromGregorian(today, adjustment: adjustment).label,style: Theme.of(context).textTheme.headlineSmall),
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        IconButton(tooltip:'Предыдущий месяц',onPressed:offset <= -120 ? null : () => setState(() {offset--;selected=null;}),icon:const Icon(Icons.chevron_left)),
        Text('${months[month.month - 1]} ${month.year}'),
        IconButton(tooltip:'Следующий месяц',onPressed:offset >= 120 ? null : () => setState(() {offset++;selected=null;}),icon:const Icon(Icons.chevron_right)),
      ]),
      if(offset != 0) TextButton(onPressed:()=>setState(() {offset=0;selected=null;}),child:const Text('Сегодня')),
      Row(children:[for(final name in ['Пн','Вт','Ср','Чт','Пт','Сб','Вс']) Expanded(child:Center(child:Text(name)))]),
      GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
        gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:7,childAspectRatio:0.85),
        itemCount:first + length,itemBuilder:(context,i){
          if(i<first) return const SizedBox.shrink();
          final date=DateTime(month.year,month.month,i-first+1);
          final h=HijriCalendar.fromGregorian(date,adjustment:adjustment);
          final active=date==day;
          final colors=Theme.of(context).colorScheme;
          return Padding(padding:const EdgeInsets.all(2),child:Material(
            color:active?colors.primaryContainer:colors.surface,
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8),side:date==today?BorderSide(color:colors.primary):BorderSide.none),
            child:InkWell(borderRadius:BorderRadius.circular(8),onTap:()=>setState(()=>selected=date),
              child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                Text('${date.day}',style:const TextStyle(fontWeight:FontWeight.w600)),
                Text('${h.day}',style:Theme.of(context).textTheme.labelSmall),
                if(h.event!=null) Icon(Icons.circle,size:5,color:colors.primary),
              ])),
          ));
        }),
      const SizedBox(height:16),
      Text(formatDate(day),style:Theme.of(context).textTheme.titleLarge),
      Text(hijri.label),
      if(hijri.event!=null) Text('${hijri.event} (расчётная дата)'),
      for(final slot in schedule.slots) ListTile(dense:true,title:Text(slot.kind.label),trailing:Text(formatTime(slot.time))),
      ListTile(title:const Text('Корректировка Хиджры'),trailing:DropdownButton<int>(value:adjustment,
        items:[for(var i=-2;i<=2;i++) DropdownMenuItem(value:i,child:Text(i>0?'+$i':'$i'))],
        onChanged:(v) async {if(v==null)return;try{await ref.read(hijriAdjustmentProvider.notifier).change(v);}catch(e){if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}})),
      const Text('Арифметический календарь по гражданской дате. Начало исламского дня после заката здесь не учитывается. Даты праздников предварительные; сверяйте с ДУМК. Корректировка не меняет время намаза.'),
    ]);
  }
}
