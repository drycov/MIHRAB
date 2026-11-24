import 'quran.dart';
class QuranSearchHit {
  const QuranSearchHit(this.surah,this.ayah);
  final Surah surah;
  final Ayah ayah;
}
String normalizeQuranSearch(String input)=>input.toLowerCase().replaceAll(RegExp(r'[\u0610-\u061a\u064b-\u065f\u0670\u06d6-\u06ed\u0640]'),'').replaceAll(RegExp(r'[أإآٱ]'),'ا').trim();
List<QuranSearchHit> searchQuran(Iterable<QuranSearchHit> verses,String query,{int limit=200}){
  final q=normalizeQuranSearch(query);
  if(q.isEmpty||limit<=0)return [];
  return verses.where((v)=>normalizeQuranSearch(v.ayah.arabic).contains(q)||normalizeQuranSearch(v.ayah.translation).contains(q)||'${v.surah.number}:${v.ayah.number}'==q).take(limit).toList();
}
