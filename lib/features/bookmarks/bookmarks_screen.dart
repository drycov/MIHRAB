import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/bookmarks.dart';
import '../../domain/bookmark.dart';
import '../../domain/dua.dart';
import '../dua/dua_screen.dart';
import '../quran/quran_screen.dart';

class BookmarksScreen extends ConsumerStatefulWidget{
  const BookmarksScreen({super.key});
  @override
  ConsumerState<BookmarksScreen> createState()=>_BookmarksScreenState();
}
class _BookmarksScreenState extends ConsumerState<BookmarksScreen>{
  String query='';
  String? collection;
  BookmarkKind? kind;
  Future<void> run(Future<void> Function() fn)async{
    try{await fn();}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Не удалось выполнить действие. Проверьте название и повторите.')));}
  }
  Future<void> createCollection()async{
    String name='';
    final result=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Новая коллекция'),
      content:TextField(autofocus:true,maxLength:60,onChanged:(v)=>name=v),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Отмена')),FilledButton(onPressed:()=>Navigator.pop(ctx,name),child:const Text('Создать'))]));
    if(result!=null&&mounted)await run(()=>ref.read(bookmarksProvider.notifier).addCollection(result));
  }
  Future<void> open(Bookmark b)async{
    await run(()async{
      if(b.kind==BookmarkKind.dua){
        final d=duas.firstWhere((d)=>d.id==b.reference);
        if(mounted)await Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>DuaDetailScreen(dua:d)));
      }else{
        final parts=b.reference.split(':');
        final number=int.parse(parts.first);
        final catalog=await ref.read(quranRepositoryProvider).catalog();
        final surah=catalog.firstWhere((s)=>s.number==number);
        final verse=b.kind==BookmarkKind.ayah?int.parse(parts.last):1;
        if(verse>surah.count)throw StateError('Invalid verse');
        if(mounted)await Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>SurahScreen(surah:surah,initialVerse:verse)));
      }
    });
  }
  Future<void> move(Bookmark b,List<String> collections)async{
    final result=await showDialog<String>(context:context,builder:(ctx)=>SimpleDialog(title:const Text('Переместить в коллекцию'),children:[
      SimpleDialogOption(onPressed:()=>Navigator.pop(ctx,''),child:const Text('Без коллекции')),
      for(final name in collections)SimpleDialogOption(onPressed:()=>Navigator.pop(ctx,name),child:Text(name)),
    ]));
    if(result!=null&&mounted)await run(()=>ref.read(bookmarksProvider.notifier).move(b.id,result));
  }
  @override
  Widget build(BuildContext context){
    final library=ref.watch(bookmarksProvider);
    final selected=collection==null||collection==''||library.collections.contains(collection)?collection:null;
    final rows=library.items.where((b)=>(selected==null||b.collection==selected)&&(kind==null||b.kind==kind)&&
      '${b.title} ${b.reference} ${b.collection}'.toLowerCase().contains(query)).toList();
    return Scaffold(appBar:AppBar(title:const Text('Избранное'),actions:[IconButton(tooltip:'Новая коллекция',onPressed:createCollection,icon:const Icon(Icons.create_new_folder_outlined))]),
      body:SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.all(12),child:TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Поиск закладок'),onChanged:(v)=>setState(()=>query=v.trim().toLowerCase()))),
        Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:DropdownButton<String>(isExpanded:true,value:selected??'__all__',items:[
          const DropdownMenuItem(value:'__all__',child:Text('Все коллекции')),
          const DropdownMenuItem(value:'',child:Text('Без коллекции')),
          for(final name in library.collections.where((c)=>c!='__all__'))DropdownMenuItem(value:name,child:Text(name)),
        ],onChanged:(v)=>setState(()=>collection=v=='__all__'?null:v))),
        if(selected!=null&&selected.isNotEmpty)TextButton.icon(icon:const Icon(Icons.delete_outline),label:const Text('Удалить коллекцию (сохранить закладки)'),onPressed:()async{
          final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Удалить коллекцию?'),content:const Text('Закладки останутся без коллекции.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Отмена')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Удалить'))]));
          if(confirmed==true&&mounted){await run(()=>ref.read(bookmarksProvider.notifier).removeCollection(selected));if(mounted)setState(()=>collection=null);}
        }),
        Wrap(spacing:6,children:[
          ChoiceChip(label:const Text('Все'),selected:kind==null,onSelected:(_)=>setState(()=>kind=null)),
          for(final k in BookmarkKind.values)ChoiceChip(label:Text(switch(k){BookmarkKind.surah=>'Суры',BookmarkKind.ayah=>'Аяты',BookmarkKind.dua=>'Дуа'}),selected:kind==k,onSelected:(_)=>setState(()=>kind=k)),
        ]),
        Expanded(child:ListView(children:[
          if(rows.isEmpty)const ListTile(title:Text('Нет сохранённых материалов')),
          for(final b in rows)ListTile(leading:const Icon(Icons.bookmark),title:Text(b.title),subtitle:Text(b.collection.isEmpty?'Без коллекции':b.collection),onTap:()=>open(b),
            trailing:PopupMenuButton<String>(onSelected:(v){if(v=='move'){move(b,library.collections);}else{run(()=>ref.read(bookmarksProvider.notifier).toggle(b));}},
              itemBuilder:(_)=>const [PopupMenuItem(value:'move',child:Text('Переместить')),PopupMenuItem(value:'delete',child:Text('Удалить'))])),
        ])),
      ])));
  }
}
