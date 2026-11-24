import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../domain/quran_audio.dart';
import 'quran_disk.dart';

class QuranAudioRepository {
  QuranAudioRepository({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static const maxBytes = 12 * 1024 * 1024;
  static const cacheBytes = 32 * 1024 * 1024;
  final _cache = <String, Uint8List>{};
  int _size = 0;
  void close() {
    _client.close();
    _cache.clear();
    _size = 0;
  }

  Future<Uri> resolve(int surah, int verse, QuranReciter reciter) async {
    if (surah < 1 || surah > 114 || verse < 1 || verse > 286)
      throw RangeError('Invalid verse');
    final response = await _client
        .get(
          Uri.https(
            'api.alquran.cloud',
            '/v1/ayah/$surah:$verse/${reciter.id}',
          ),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 || response.bodyBytes.length > 1024 * 1024)
      throw StateError('Audio API unavailable');
    final envelope = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    if (envelope['code'] != 200) throw StateError('Audio API error');
    return QuranAudioCodec.decode(
      envelope['data'],
      surah: surah,
      verse: verse,
      reciter: reciter,
    );
  }

  String key(int surah, int verse, QuranReciter reciter) =>
      '${reciter.id}:$surah:$verse';
  Uint8List? cached(int surah, int verse, QuranReciter reciter) {
    final k = key(surah, verse, reciter);
    final bytes = _cache.remove(k);
    if (bytes != null) _cache[k] = bytes;
    return bytes;
  }

  Future<Uint8List?> local(int surah, int verse, QuranReciter reciter) async =>
      cached(surah, verse, reciter) ??
      await QuranDisk.read(key(surah, verse, reciter));
  Future<void> cache(int surah, int verse, QuranReciter reciter) async {
    if (await local(surah, verse, reciter) != null) return;
    final uri = await resolve(surah, verse, reciter);
    final request = http.Request('GET', uri)..followRedirects = false;
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 ||
        (response.contentLength ?? 0) > maxBytes) {
      final subscription = response.stream.listen((_) {});
      await subscription.cancel();
      throw StateError('Audio unavailable or too large');
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 20),
    )) {
      if (builder.length + chunk.length > maxBytes)
        throw StateError('Audio exceeds cache limit');
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    if (bytes.isEmpty) throw const FormatException('Empty audio');
    final k = key(surah, verse, reciter);
    await QuranDisk.write(k, bytes);
    _size -= _cache.remove(k)?.length ?? 0;
    while (_size + bytes.length > cacheBytes && _cache.isNotEmpty) {
      _size -= _cache.remove(_cache.keys.first)!.length;
    }
    _cache[k] = bytes;
    _size += bytes.length;
  }
}
