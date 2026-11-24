import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/quran.dart';
void main(){
  test('rejects incomplete catalog',()=>expect(()=>QuranCodec.catalog([]),throwsFormatException));
  test('matches editions by identifier and verse numbers',(){
    const surah=Surah(1,'name','test',1);
    Map<String,dynamic> edition(String id,String text,int number)=>{'number':1,'edition':{'identifier':id},'ayahs':[{'number':number,'numberInSurah':1,'text':text}]};
    final ar=edition('quran-uthmani','fixture Arabic',1);
    final tr=edition('ru.kuliev','fixture translation',1);
    expect(QuranCodec.verses([tr,ar],surah,QuranTranslation.russian).single.translation,'fixture translation');
    expect(()=>QuranCodec.verses([ar,edition('ru.kuliev','fixture',2)],surah,QuranTranslation.russian),throwsFormatException);
  });
}
