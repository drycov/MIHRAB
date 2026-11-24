import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../l10n/mihrab_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/settings.dart';
import '../../domain/quran.dart';
import '../../domain/quran_audio.dart';
import '../../infrastructure/quran_audio_repository.dart';
import '../../infrastructure/quran_disk.dart';

class QuranAudioScreen extends ConsumerStatefulWidget{
  const QuranAudioScreen({super.key,required this.surah,required this.initialVerse});
  final Surah surah;
  final int initialVerse;
  @override
  ConsumerState<QuranAudioScreen> createState()=>_QuranAudioScreenState();
}
class _QuranAudioScreenState extends ConsumerState<QuranAudioScreen> with WidgetsBindingObserver{
  final player=AudioPlayer();
  final repository=QuranAudioRepository();
  late QuranReciter reciter;
  late int verse;
  QuranPlaybackMode mode=QuranPlaybackMode.sequential;
  PlayerState playback=PlayerState.stopped;
  Duration position=Duration.zero,duration=Duration.zero;
  final subscriptions=<StreamSubscription<dynamic>>[];
  bool busy=false,active=true;
  String? error;
  int generation=0;
  @override
  void initState(){
    super.initState();
    verse=widget.initialVerse.clamp(1,widget.surah.count).toInt();
    final saved=ref.read(preferencesProvider).getString('quran_reciter');
    reciter=QuranReciter.values.firstWhere((r)=>r.id==saved,orElse:()=>QuranReciter.alafasy);
    WidgetsBinding.instance.addObserver(this);
    subscriptions.add(player.onPlayerStateChanged.listen((s){if(mounted)setState(()=>playback=s);}));
    subscriptions.add(player.onPositionChanged.listen((p){if(mounted)setState(()=>position=p);}));
    subscriptions.add(player.onDurationChanged.listen((d){if(mounted)setState(()=>duration=d);}));
    subscriptions.add(player.onPlayerComplete.listen((_){
      if(!mounted||busy||!active)return;
      final next=QuranAudioCodec.next(verse,widget.surah.count,mode);
      if(next!=null){setState(()=>verse=next);play();}
    }));
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    active=state==AppLifecycleState.resumed;
    if(!active){generation++;unawaited(player.stop().catchError((Object _){}));}
  }
  Future<void> play()async{
    if(busy||!active)return;
    final token=++generation;
    setState((){busy=true;error=null;position=Duration.zero;duration=Duration.zero;});
    try{
      await player.stop();
      final bytes=await repository.local(widget.surah.number,verse,reciter);
      final source=bytes!=null&&!kIsWeb?BytesSource(bytes):UrlSource((await repository.resolve(widget.surah.number,verse,reciter)).toString());
      if(!mounted||!active||generation!=token)return;
      await player.play(source);
      if(!active||generation!=token)await player.stop();
    }catch(_){if(mounted&&generation==token)setState(()=>error='Не удалось воспроизвести аят. Проверьте соединение.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> action(Future<void> Function() fn)async{
    if(busy)return;
    setState((){busy=true;error=null;});
    try{await fn();}
    catch(_){if(mounted)setState(()=>error='Не удалось выполнить действие.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> selectVerse(int value)async{
    await action(()async{generation++;await player.stop();if(mounted)setState((){verse=value;position=Duration.zero;duration=Duration.zero;});});
  }
  @override
  void dispose(){
    generation++;active=false;
    WidgetsBinding.instance.removeObserver(this);
    for(final subscription in subscriptions){unawaited(subscription.cancel());}
    repository.close();
    unawaited(player.dispose());
    super.dispose();
  }
  String time(Duration d)=>'${d.inMinutes}:${(d.inSeconds%60).toString().padLeft(2,'0')}';
  @override
  Widget build(BuildContext context){
    final playing=playback==PlayerState.playing;
    final paused=playback==PlayerState.paused;
    
    return Scaffold(appBar:AppBar(title:Text(context.tr('Аудио Корана'))),body:SafeArea(child:ListView(padding:const EdgeInsets.all(20),children:[
      Text(widget.surah.name,textDirection:TextDirection.rtl,textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineLarge),
      Text(widget.surah.transliteration,textAlign:TextAlign.center),
      const SizedBox(height:20),
      DropdownButton<QuranReciter>(isExpanded:true,value:reciter,items:[for(final r in QuranReciter.values)DropdownMenuItem(value:r,child:Text(r.label))],
        onChanged:busy?null:(r){if(r!=null)action(()async{generation++;await player.stop();if(!mounted)return;setState((){reciter=r;position=Duration.zero;duration=Duration.zero;});await ref.read(preferencesProvider).setString('quran_reciter',r.id);});}),
      DropdownButton<QuranPlaybackMode>(isExpanded:true,value:mode,items:[for(final m in QuranPlaybackMode.values)DropdownMenuItem(value:m,child:Text(m.label))],
        onChanged:busy?null:(m){if(m!=null)setState(()=>mode=m);}),
      const SizedBox(height:12),
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        IconButton(tooltip:'Предыдущий аят',onPressed:busy||verse<=1?null:()=>selectVerse(verse-1),icon:const Icon(Icons.skip_previous)),
        DropdownButton<int>(value:verse,items:[for(var i=1;i<=widget.surah.count;i++)DropdownMenuItem(value:i,child:Text('Аят $i'))],onChanged:busy?null:(v){if(v!=null)selectVerse(v);}),
        IconButton(tooltip:'Следующий аят',onPressed:busy||verse>=widget.surah.count?null:()=>selectVerse(verse+1),icon:const Icon(Icons.skip_next)),
      ]),
      Slider(value:duration.inMilliseconds==0?0:position.inMilliseconds.clamp(0,duration.inMilliseconds).toDouble(),
        max:duration.inMilliseconds==0?1:duration.inMilliseconds.toDouble(),
        onChanged:busy||duration.inMilliseconds==0||(!playing&&!paused)?null:(v)=>action(()=>player.seek(Duration(milliseconds:v.round())))),
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(time(position)),Text(time(duration))]),
      Row(mainAxisAlignment:MainAxisAlignment.center,children:[
        IconButton.filledTonal(tooltip:'Остановить',onPressed:busy?null:()=>action(()async{generation++;await player.stop();if(mounted)setState(()=>position=Duration.zero);}),icon:const Icon(Icons.stop)),
        const SizedBox(width:12),
        IconButton.filled(tooltip:playing?'Пауза':'Воспроизвести',iconSize:48,onPressed:busy?null:playing?()=>action(player.pause):paused?()=>action(player.resume):play,icon:Icon(playing?Icons.pause:Icons.play_arrow)),
      ]),
      if(busy)const LinearProgressIndicator(),
      if(error!=null)Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
      if(QuranDisk.supported) FutureBuilder<bool>(future:QuranDisk.contains(repository.key(widget.surah.number,verse,reciter)),builder:(context,snapshot){
        final saved=snapshot.data==true;
        return OutlinedButton.icon(onPressed:busy||saved?null:()=>action(()=>repository.cache(widget.surah.number,verse,reciter)),icon:Icon(saved?Icons.check:Icons.download),label:Text(saved?'Аят доступен офлайн':'Скачать текущий аят'));
      }),
      const Text('Источник: Al Quran Cloud / Islamic Network. Воспроизведение останавливается при уходе с экрана или сворачивании. Загруженные аяты сохраняются на устройстве.'),
    ])));
  }
}
