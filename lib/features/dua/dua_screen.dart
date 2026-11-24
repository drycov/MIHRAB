import 'package:flutter/material.dart';
import '../../l10n/mihrab_strings.dart';
import 'package:flutter/services.dart';
import '../../domain/dua.dart';
import '../../domain/bookmark.dart';
import '../bookmarks/bookmark_button.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../tasbih/tasbih_screen.dart';

class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});
  @override
  State<DuaScreen> createState()=>_DuaScreenState();
}
class _DuaScreenState extends State<DuaScreen>{
  DuaCategory? category;
  String query='';
  @override
  Widget build(BuildContext context){
    final filtered=duas.where((d)=>(category==null||d.category==category)&&
      [d.title,d.meaning,d.transliteration,d.arabic].any((s)=>s.toLowerCase().contains(query))).toList();
    return Scaffold(appBar:AppBar(title:Text(context.tr('Дуа и азкары')),actions:[IconButton(tooltip:'Избранное',icon:const Icon(Icons.bookmarks_outlined),onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const BookmarksScreen()))),IconButton(tooltip:'Тасбих',icon:const Icon(Icons.touch_app),onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const TasbihScreen())))]),
      body:SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.all(16),child:TextField(
          decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Поиск дуа и азкаров'),
          onChanged:(v)=>setState(()=>query=v.trim().toLowerCase()))),
        SingleChildScrollView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),child:Row(children:[
          Padding(padding:const EdgeInsets.all(4),child:ChoiceChip(label:const Text('Все'),selected:category==null,onSelected:(_)=>setState(()=>category=null))),
          for(final c in DuaCategory.values) Padding(padding:const EdgeInsets.all(4),child:ChoiceChip(label:Text(c.label),selected:category==c,onSelected:(_)=>setState(()=>category=c))),
        ])),
        Expanded(child:ListView(padding:const EdgeInsets.all(12),children:[
          if(filtered.isEmpty)const ListTile(title:Text('Ничего не найдено')),
          for(final d in filtered) Card(child:ListTile(title:Text(d.title),subtitle:Text('${d.category.label} · ${d.repetitions} повторений'),trailing:const Icon(Icons.chevron_right),
            onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>DuaDetailScreen(dua:d))))),
        ])),
      ])));
  }
}
class DuaDetailScreen extends StatefulWidget{
  const DuaDetailScreen({super.key,required this.dua});
  final Dua dua;
  @override
  State<DuaDetailScreen> createState()=>_DuaDetailScreenState();
}
class _DuaDetailScreenState extends State<DuaDetailScreen>{
  int count=0;
  @override
  Widget build(BuildContext context){
    final d=widget.dua;
    final done=count>=d.repetitions;
    return Scaffold(appBar:AppBar(title:Text(d.title),actions:[BookmarkButton(bookmark:Bookmark(kind:BookmarkKind.dua,reference:d.id,title:d.title))]),body:SafeArea(child:ListView(padding:const EdgeInsets.all(20),children:[
      Text(d.category.label,style:Theme.of(context).textTheme.labelLarge),
      const SizedBox(height:20),
      SelectableText(d.arabic,textDirection:TextDirection.rtl,textAlign:TextAlign.right,style:const TextStyle(fontSize:30,height:2)),
      const Divider(height:32),
      Text(d.transliteration,style:Theme.of(context).textTheme.titleMedium),
      const SizedBox(height:12),
      const Text('Смысловой перевод'),
      SelectableText(d.meaning,style:const TextStyle(fontSize:18,height:1.6)),
      const SizedBox(height:20),
      LinearProgressIndicator(value:count/d.repetitions),
      const SizedBox(height:12),
      Text('$count / ${d.repetitions}',textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineMedium),
      FilledButton(onPressed:done?null:()=>setState(()=>count++),child:Text(done?'Завершено':'Отметить повторение')),
      TextButton(onPressed:count==0?null:()=>setState(()=>count=0),child:const Text('Сбросить счётчик')),
      const Divider(),
      Text('Источник: ${d.source}'),
      SelectableText(d.url),
      TextButton.icon(onPressed:()async{await Clipboard.setData(ClipboardData(text:d.url));if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Ссылка скопирована')));},icon:const Icon(Icons.copy),label:const Text('Копировать ссылку')),
      const Text('Транслитерация приблизительная. Для правильного произношения сверяйтесь с арабским текстом.'),
    ])));
  }
}
