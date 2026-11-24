import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/tasbih.dart';
import '../../domain/tasbih.dart';

class TasbihScreen extends ConsumerWidget{
  const TasbihScreen({super.key});
  Future<void> run(BuildContext context,Future<void> Function() action)async{
    try{await action();}catch(_){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Не удалось сохранить изменения')));}
  }
  Future<bool> confirm(BuildContext context,String title)async=>await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
    title:Text(title),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Отмена')),
      FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Подтвердить'))]))??false;
  Future<void> configure(BuildContext context,WidgetRef ref,Dhikr d,int target)async{
    final current=ref.read(tasbihProvider);
    if(current.dhikr==d&&current.target==target)return;
    if(current.count>0&&!current.complete&&!await confirm(context,'Начать новый счёт? Текущий прогресс будет сброшен.'))return;
    if(!context.mounted)return;
    await run(context,()=>ref.read(tasbihProvider.notifier).configure(d,target));
  }
  Future<void> custom(BuildContext context,WidgetRef ref)async{
    final controller=TextEditingController(text:ref.read(tasbihProvider).target.toString());
    final goal=await showDialog<int>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setLocal){
      final value=int.tryParse(controller.text);
      final valid=value!=null&&value>=1&&value<=9999;
      return AlertDialog(title:const Text('Произвольная цель'),content:TextField(controller:controller,
        autofocus:true,keyboardType:TextInputType.number,inputFormatters:[FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(4)],
        decoration:const InputDecoration(labelText:'От 1 до 9999'),onChanged:(_)=>setLocal((){})),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Отмена')),
          FilledButton(onPressed:valid?()=>Navigator.pop(ctx,value):null,child:const Text('Применить'))]);
    }));
    controller.dispose();
    if(goal!=null&&context.mounted)await configure(context,ref,ref.read(tasbihProvider).dhikr,goal);
  }
  @override
  Widget build(BuildContext context,WidgetRef ref){
    final s=ref.watch(tasbihProvider);
    final c=ref.read(tasbihProvider.notifier);
    final theme=Theme.of(context);
    return Scaffold(appBar:AppBar(title:const Text('Тасбих'),actions:[
      IconButton(tooltip:'История',icon:const Icon(Icons.history),onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const TasbihHistoryScreen())))]),
      body:SafeArea(child:ListView(padding:const EdgeInsets.all(20),children:[
        DropdownButton<Dhikr>(isExpanded:true,value:s.dhikr,items:[for(final d in Dhikr.values)DropdownMenuItem(value:d,child:Text(d.label))],
          onChanged:(d){if(d!=null)configure(context,ref,d,s.target);}),
        if(s.dhikr.arabic.isNotEmpty)Text(s.dhikr.arabic,textDirection:TextDirection.rtl,textAlign:TextAlign.center,style:theme.textTheme.headlineMedium),
        const SizedBox(height:12),
        Wrap(spacing:8,runSpacing:8,children:[
          for(final goal in [33,99,100])ChoiceChip(label:Text('$goal'),selected:s.target==goal,onSelected:(_)=>configure(context,ref,s.dhikr,goal)),
          ActionChip(label:Text([33,99,100].contains(s.target)?'Своя цель':'Цель: ${s.target}'),onPressed:()=>custom(context,ref)),
        ]),
        const SizedBox(height:24),
        Center(child:Semantics(button:true,label:'Увеличить счётчик',value:'${s.count} из ${s.target}',child:SizedBox(width:220,height:220,child:Stack(alignment:Alignment.center,children:[
          SizedBox.expand(child:CircularProgressIndicator(value:s.count/s.target,strokeWidth:7,backgroundColor:theme.colorScheme.surfaceContainerHighest)),
          SizedBox(width:196,height:196,child:FilledButton(style:FilledButton.styleFrom(shape:const CircleBorder(),padding:EdgeInsets.zero),
            onPressed:s.complete?null:()=>run(context,()async{
              final before=ref.read(tasbihProvider);
              await c.increment();
              if(!context.mounted)return;
              final after=ref.read(tasbihProvider);
              if(after.count!=before.count&&after.haptic){
                if(after.complete){await HapticFeedback.mediumImpact();}else{await HapticFeedback.selectionClick();}
              }
            }),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              Text('${s.count}',style:const TextStyle(fontSize:48)),
              Text('из ${s.target}'),
              Text(s.complete?'Завершено':'Нажмите'),
            ]))),
        ])))),
        const SizedBox(height:24),
        FilledButton.tonalIcon(onPressed:s.count==0?null:()async{
          if(s.complete||await confirm(context,'Сбросить текущий счёт?')){
            if(context.mounted)await run(context,c.reset);
          }
        },icon:const Icon(Icons.restart_alt),label:Text(s.complete?'Новая сессия':'Сбросить')),
        SwitchListTile(title:const Text('Тактильный отклик'),value:s.haptic,onChanged:(v)=>run(context,()=>c.vibration(v))),
        const Text('Цели счёта настраиваются пользователем и сами по себе не являются религиозным предписанием.'),
      ])));
  }
}

class TasbihHistoryScreen extends ConsumerWidget{
  const TasbihHistoryScreen({super.key});
  @override
  Widget build(BuildContext context,WidgetRef ref){
    final history=ref.watch(tasbihProvider).history;
    final helper=const TasbihScreen();
    return Scaffold(appBar:AppBar(title:const Text('История тасбиха'),actions:[
      IconButton(tooltip:'Очистить историю',icon:const Icon(Icons.delete_outline),onPressed:history.isEmpty?null:()async{
        if(await helper.confirm(context,'Удалить историю завершённых сессий?')&&context.mounted){
          await helper.run(context,ref.read(tasbihProvider.notifier).clearHistory);
        }
      })]),body:SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[
        Card(child:ListTile(title:Text('Сессий: ${history.length}'),subtitle:Text('Повторений в сохранённых сессиях: ${history.fold<int>(0,(sum,s)=>sum+s.target)}'))),
        if(history.isEmpty)const ListTile(title:Text('История пока пуста')),
        for(final item in history)ListTile(leading:const Icon(Icons.check_circle_outline),title:Text(item.dhikr.label),subtitle:Text(MaterialLocalizations.of(context).formatMediumDate(item.completedAt.toLocal())),trailing:Text('${item.target}')),
        const Text('Хранятся последние 100 завершённых сессий.'),
      ])));
  }
}
