import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/settings.dart';
import '../dua/dua_screen.dart';
import '../../domain/bookmark.dart';
import '../bookmarks/bookmark_button.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../tasbih/tasbih_screen.dart';
import '../../domain/quran.dart';
import 'quran_audio_screen.dart';
import '../../infrastructure/quran_repository.dart';

final quranRepositoryProvider=Provider<QuranRepository>((ref){
  final repo=QuranRepository(ref.watch(preferencesProvider));
  ref.onDispose(repo.close);
  return repo;
});
final quranCatalogProvider=FutureProvider.autoDispose<List<Surah>>((ref)=>ref.watch(quranRepositoryProvider).catalog());

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});
  @override
  ConsumerState<QuranScreen> createState()=>_QuranScreenState();
}
class _QuranScreenState extends ConsumerState<QuranScreen>{
  String query='';
  void open(Surah surah,{int verse=1})=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>SurahScreen(surah:surah,initialVerse:verse)));
  @override
  Widget build(BuildContext context){
    final catalog=ref.watch(quranCatalogProvider);
    final prefs=ref.watch(preferencesProvider);
    return Scaffold(appBar:AppBar(title:const Text('Коран'),actions:[IconButton(tooltip:'Избранное',icon:const Icon(Icons.bookmarks_outlined),onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const BookmarksScreen()))),IconButton(tooltip:'Тасбих',icon:const Icon(Icons.touch_app),onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const TasbihScreen()))),IconButton(tooltip:'Дуа и азкары',icon:const Icon(Icons.auto_stories),onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const DuaScreen())))]),
      body:SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.all(16),child:TextField(
          decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Название или номер суры'),
          onChanged:(v)=>setState(()=>query=v.trim().toLowerCase()))),
        Expanded(child:catalog.when(
          loading:()=>const Center(child:CircularProgressIndicator()),
          error:(e,s)=>Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
            const Text('Не удалось загрузить каталог. Проверьте интернет.'),
            TextButton(onPressed:()=>ref.invalidate(quranCatalogProvider),child:const Text('Повторить'))])),
          data:(surahs){
            final last=prefs.getInt('quran_last_surah')??0;
            final filtered=surahs.where((s)=>query.isEmpty||s.number.toString()==query||s.name.contains(query)||s.transliteration.toLowerCase().contains(query)).toList();
            return ListView(children:[
              if(last>=1&&last<=114&&query.isEmpty) ListTile(leading:const Icon(Icons.history),title:const Text('Продолжить чтение'),
                subtitle:Text(surahs[last-1].transliteration),onTap:()=>open(surahs[last-1],verse:prefs.getInt('quran_last_verse')??1)),
              for(final s in filtered) ListTile(leading:CircleAvatar(child:Text('${s.number}')),title:Text(s.transliteration),
                subtitle:Text('${s.name} · ${s.count} аятов'),trailing:BookmarkButton(bookmark:Bookmark(kind:BookmarkKind.surah,reference:s.number.toString(),title:s.transliteration)),onTap:()=>open(s)),
              if(filtered.isEmpty)const ListTile(title:Text('Суры не найдены')),
            ]);
          })),
      ])));
  }
}

class SurahScreen extends ConsumerStatefulWidget{
  const SurahScreen({super.key,required this.surah,this.initialVerse=1});
  final Surah surah;
  final int initialVerse;
  @override
  ConsumerState<SurahScreen> createState()=>_SurahScreenState();
}
class _SurahScreenState extends ConsumerState<SurahScreen>{
  late QuranTranslation translation;
  late Future<List<Ayah>> future;
  late int verse;
  double fontSize=28;
  @override
  void initState(){
    super.initState();
    final saved=ref.read(preferencesProvider).getString('quran_translation');
    translation=QuranTranslation.values.firstWhere((t)=>t.id==saved,orElse:()=>QuranTranslation.russian);
    verse=widget.initialVerse.clamp(1,widget.surah.count).toInt();
    future=ref.read(quranRepositoryProvider).verses(widget.surah,translation);
  }
  Future<void> remember()async{
    final prefs=ref.read(preferencesProvider);
    final a=await prefs.setInt('quran_last_surah',widget.surah.number);
    final b=await prefs.setInt('quran_last_verse',verse);
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(a&&b?'Позиция сохранена':'Не удалось сохранить позицию')));
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.surah.transliteration),actions:[
      IconButton(tooltip:'Слушать аят',icon:const Icon(Icons.headphones),onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>QuranAudioScreen(surah:widget.surah,initialVerse:verse)))),
      BookmarkButton(bookmark:Bookmark(kind:BookmarkKind.ayah,reference:'${widget.surah.number}:$verse',title:'${widget.surah.transliteration} · $verse')),
      IconButton(tooltip:'Сохранить позицию',onPressed:remember,icon:const Icon(Icons.bookmark_add_outlined))]),
    body:SafeArea(child:Column(children:[
      Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:DropdownButton<QuranTranslation>(
        isExpanded:true,value:translation,items:[for(final t in QuranTranslation.values) DropdownMenuItem(value:t,child:Text(t.label))],
        onChanged:(t){if(t==null)return;setState((){translation=t;future=ref.read(quranRepositoryProvider).verses(widget.surah,t);});ref.read(preferencesProvider).setString('quran_translation',t.id);})),
      Row(children:[const SizedBox(width:16),const Text('Размер текста'),Expanded(child:Slider(value:fontSize,min:20,max:44,onChanged:(v)=>setState(()=>fontSize=v)))]),
      Expanded(child:FutureBuilder<List<Ayah>>(future:future,builder:(context,snapshot){
        if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
        if(snapshot.hasError||!snapshot.hasData)return Center(child:TextButton(onPressed:()=>setState(()=>future=ref.read(quranRepositoryProvider).verses(widget.surah,translation,refresh:true)),child:const Text('Ошибка загрузки. Повторить')));
        final ayah=snapshot.data![verse-1];
        return ListView(padding:const EdgeInsets.all(20),children:[
          Text(widget.surah.name,textDirection:TextDirection.rtl,textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height:24),
          SelectableText(ayah.arabic,textDirection:TextDirection.rtl,textAlign:TextAlign.right,style:TextStyle(fontSize:fontSize,height:2)),
          const Divider(height:40),
          SelectableText(ayah.translation,style:const TextStyle(fontSize:18,height:1.6)),
          const SizedBox(height:16),
          Text('Аят ${widget.surah.number}:$verse · ${translation.label}'),
        ]);
      })),
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        IconButton(tooltip:'Предыдущий аят',onPressed:verse>1?()=>setState(()=>verse--):null,icon:const Icon(Icons.chevron_left)),
        DropdownButton<int>(value:verse,items:[for(var i=1;i<=widget.surah.count;i++)DropdownMenuItem(value:i,child:Text('$i / ${widget.surah.count}'))],onChanged:(v){if(v!=null)setState(()=>verse=v);}),
        IconButton(tooltip:'Следующий аят',onPressed:verse<widget.surah.count?()=>setState(()=>verse++):null,icon:const Icon(Icons.chevron_right)),
      ]),
    ])));
}
