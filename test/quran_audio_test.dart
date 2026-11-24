import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/quran_audio.dart';

void main() {
  test('validates ayah identity and trusted CDN', () {
    final data = <String, dynamic>{
      'surah': {'number': 2},
      'numberInSurah': 255,
      'number': 262,
      'edition': {'identifier': 'ar.alafasy'},
      'audio': 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/262.mp3',
    };
    expect(
      QuranAudioCodec.decode(
        data,
        surah: 2,
        verse: 255,
        reciter: QuranReciter.alafasy,
      ).host,
      'cdn.islamic.network',
    );
    expect(
      () => QuranAudioCodec.decode(
        data,
        surah: 2,
        verse: 254,
        reciter: QuranReciter.alafasy,
      ),
      throwsFormatException,
    );
    data['audio'] = 'https://example.org/262.mp3';
    expect(
      () => QuranAudioCodec.decode(
        data,
        surah: 2,
        verse: 255,
        reciter: QuranReciter.alafasy,
      ),
      throwsFormatException,
    );
  });
  test('playback modes respect surah boundary', () {
    expect(QuranAudioCodec.next(1, 7, QuranPlaybackMode.sequential), 2);
    expect(QuranAudioCodec.next(7, 7, QuranPlaybackMode.sequential), isNull);
    expect(QuranAudioCodec.next(7, 7, QuranPlaybackMode.repeat), 7);
    expect(QuranAudioCodec.next(1, 7, QuranPlaybackMode.single), isNull);
  });
}
