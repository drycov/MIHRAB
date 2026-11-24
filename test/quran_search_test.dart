import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/quran.dart';
import 'package:mihrab/domain/quran_search.dart';

void main() {
  const s = Surah(1, 'name', 'name', 7);
  const rows = [
    QuranSearchHit(s, Ayah(1, 'سَلَام', 'Мир')),
    QuranSearchHit(s, Ayah(2, 'أمل', 'Надежда')),
  ];
  test('normalizes Arabic marks and translation case', () {
    expect(searchQuran(rows, 'سلام').single.ayah.number, 1);
    expect(searchQuran(rows, 'امل').single.ayah.number, 2);
    expect(searchQuran(rows, 'МИР').single.ayah.number, 1);
    expect(searchQuran(rows, '1:2').single.ayah.number, 2);
    expect(searchQuran(rows, ' '), isEmpty);
  });
}
