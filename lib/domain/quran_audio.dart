enum QuranReciter {
  alafasy('ar.alafasy', 'Мишари Рашид аль-Афаси'),
  sudais('ar.abdurrahmaansudais', 'Абдуррахман ас-Судейс');

  const QuranReciter(this.id, this.label);
  final String id, label;
}

enum QuranPlaybackMode {
  single('Один аят'),
  sequential('До конца суры'),
  repeat('Повтор аята');

  const QuranPlaybackMode(this.label);
  final String label;
}

abstract final class QuranAudioCodec {
  static Uri decode(
    Object? data, {
    required int surah,
    required int verse,
    required QuranReciter reciter,
  }) {
    if (data is! Map ||
        data['surah'] is! Map ||
        data['edition'] is! Map ||
        data['surah']['number'] != surah ||
        data['numberInSurah'] != verse ||
        data['edition']['identifier'] != reciter.id) {
      throw const FormatException('Audio identity mismatch');
    }
    final number = data['number'];
    if (number is! int || number < 1 || number > 6236)
      throw const FormatException('Invalid ayah number');
    final url = Uri.parse(data['audio'] as String);
    if (url.scheme != 'https' ||
        url.host != 'cdn.islamic.network' ||
        url.userInfo.isNotEmpty ||
        url.hasPort ||
        url.hasQuery ||
        url.hasFragment ||
        url.pathSegments.length != 5 ||
        url.pathSegments[0] != 'quran' ||
        url.pathSegments[1] != 'audio' ||
        !['32', '40', '48', '64', '128', '192'].contains(url.pathSegments[2]) ||
        url.pathSegments[3] != reciter.id ||
        url.pathSegments[4] != '$number.mp3') {
      throw const FormatException('Invalid audio source');
    }
    return url;
  }

  static int? next(int verse, int count, QuranPlaybackMode mode) =>
      switch (mode) {
        QuranPlaybackMode.single => null,
        QuranPlaybackMode.repeat => verse,
        QuranPlaybackMode.sequential => verse < count ? verse + 1 : null,
      };
}
