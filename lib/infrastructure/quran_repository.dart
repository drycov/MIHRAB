import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/quran.dart';

class QuranRepository {
  QuranRepository(this.prefs,{http.Client? client}):_client=client??http.Client();
  final SharedPreferences prefs;
  final http.Client _client;
  void close()=>_client.close();
  Future<T> _read<T>(String key,String path,T Function(Object?) decode,{bool refresh=false}) async {
    final cached=prefs.getString(key);
    if(!refresh&&cached!=null){
      try{return decode(jsonDecode(cached));}catch(_){}
    }
    try{
      final response=await _client.get(Uri.https('api.alquran.cloud','/v1/$path')).timeout(const Duration(seconds:25));
      if(response.statusCode!=200||response.bodyBytes.length>4*1024*1024)throw StateError('Quran API unavailable');
      final envelope=jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      if(envelope['code']!=200)throw StateError('Quran API error');
      final data=envelope['data'];
      final result=decode(data);
      if(!await prefs.setString(key,jsonEncode(data)))throw StateError('Cache write failed');
      return result;
    }catch(_){
      if(cached!=null)return decode(jsonDecode(cached));
      rethrow;
    }
  }
  List<Surah>? cachedCatalog(){
    try{return QuranCodec.catalog(jsonDecode(prefs.getString('quran_catalog_v1')!));}catch(_){return null;}
  }
  List<Ayah>? cachedVerses(Surah surah,QuranTranslation translation){
    try{return QuranCodec.verses(jsonDecode(prefs.getString('quran_v1_${surah.number}_${translation.id}')!),surah,translation);}catch(_){return null;}
  }
  Future<void> removeTranslation(QuranTranslation translation)async{
    for(var n=1;n<=114;n++){
      if(!await prefs.remove('quran_v1_${n}_${translation.id}'))throw StateError('Cache removal failed');
    }
  }
  Future<List<Surah>> catalog({bool refresh=false})=>_read('quran_catalog_v1','surah',QuranCodec.catalog,refresh:refresh);
  Future<List<Ayah>> verses(Surah surah,QuranTranslation translation,{bool refresh=false})=>
    _read('quran_v1_${surah.number}_${translation.id}',
      'surah/${surah.number}/editions/quran-uthmani,${translation.id}',
      (data)=>QuranCodec.verses(data,surah,translation),refresh:refresh);
}
