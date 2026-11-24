class Surah {
  const Surah(this.number, this.name, this.transliteration, this.count);
  final int number, count;
  final String name, transliteration;
  factory Surah.fromJson(Map<String, dynamic> json) {
    final n = json['number'] as int;
    final count = json['numberOfAyahs'] as int;
    if (n < 1 || n > 114 || count < 1 || count > 286)
      throw const FormatException('Invalid surah');
    return Surah(
      n,
      json['name'] as String,
      json['englishName'] as String,
      count,
    );
  }
}

class Ayah {
  const Ayah(this.number, this.arabic, this.translation);
  final int number;
  final String arabic, translation;
}

enum QuranTranslation {
  russian('ru.kuliev', 'Русский · Э. Кулиев'),
  english('en.pickthall', 'English · M. Pickthall');

  const QuranTranslation(this.id, this.label);
  final String id, label;
}

abstract final class QuranCodec {
  static List<Surah> catalog(Object? data) {
    if (data is! List || data.length != 114)
      throw const FormatException('Incomplete catalog');
    final result =
        data
            .map((x) => Surah.fromJson(Map<String, dynamic>.from(x as Map)))
            .toList();
    for (var i = 0; i < result.length; i++) {
      if (result[i].number != i + 1)
        throw const FormatException('Invalid surah order');
    }
    if (result.fold<int>(0, (sum, s) => sum + s.count) != 6236)
      throw const FormatException('Invalid verse count');
    return result;
  }

  static List<Ayah> verses(
    Object? data,
    Surah surah,
    QuranTranslation translation,
  ) {
    if (data is! List || data.length != 2)
      throw const FormatException('Missing editions');
    List<dynamic> edition(String id) {
      final entry = data.cast<Map>().singleWhere(
        (e) => e['edition'] is Map && e['edition']['identifier'] == id,
      );
      if (entry['number'] != surah.number)
        throw const FormatException('Wrong surah');
      final rows = entry['ayahs'] as List;
      if (rows.length != surah.count)
        throw const FormatException('Incomplete verses');
      return rows;
    }

    final ar = edition('quran-uthmani'), tr = edition(translation.id);
    return List.generate(surah.count, (i) {
      final a = ar[i] as Map, t = tr[i] as Map;
      if (a['numberInSurah'] != i + 1 ||
          t['numberInSurah'] != i + 1 ||
          a['number'] != t['number'])
        throw const FormatException('Verse mismatch');
      final text = a['text'] as String, translated = t['text'] as String;
      if (text.trim().isEmpty || translated.trim().isEmpty)
        throw const FormatException('Empty verse');
      return Ayah(i + 1, text, translated);
    });
  }
}
