import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class QuranDisk {
  static const supported = true;
  static const limit = 256 * 1024 * 1024;
  static const maxTrack = 12 * 1024 * 1024;
  static Future<void> _tail = Future.value();
  static Future<T> _serial<T>(Future<T> Function() fn) {
    final task = _tail.then((_) => fn());
    _tail = task.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return task;
  }

  static Future<Directory> _root() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/quran_audio_v1').create(recursive: true);
  }

  static String _name(String key) {
    if (!RegExp(r'^[a-z.]+:[0-9]{1,3}:[0-9]{1,3}$').hasMatch(key))
      throw const FormatException('Invalid audio key');
    return '${key.replaceAll(':', '_')}.mp3';
  }

  static Future<int> _size(Directory root) async {
    var total = 0;
    await for (final f in root.list(followLinks: false)) {
      if (f is File && f.path.endsWith('.mp3')) total += await f.length();
    }
    return total;
  }

  static Future<Uint8List?> read(String key) => _serial(() async {
    final root = await _root();
    final f = File('${root.path}/${_name(key)}');
    if (await FileSystemEntity.type(f.path, followLinks: false) !=
        FileSystemEntityType.file)
      return null;
    final length = await f.length();
    if (length <= 0 || length > maxTrack) return null;
    return f.readAsBytes();
  });
  static Future<bool> contains(String key) => _serial(() async {
    final root = await _root();
    final f = File('${root.path}/${_name(key)}');
    if (await FileSystemEntity.type(f.path, followLinks: false) !=
        FileSystemEntityType.file)
      return false;
    final n = await f.length();
    return n > 0 && n <= maxTrack;
  });
  static Future<int> size() => _serial(() async => _size(await _root()));
  static Future<void> write(String key, Uint8List bytes) => _serial(() async {
    if (bytes.isEmpty || bytes.length > maxTrack)
      throw const FormatException('Invalid audio size');
    final root = await _root();
    final f = File('${root.path}/${_name(key)}');
    final old = await f.exists() ? await f.length() : 0;
    if (await _size(root) - old + bytes.length > limit)
      throw StateError('Audio quota exceeded');
    final temp = File('${f.path}.tmp');
    try {
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(f.path);
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  });
  static Future<void> clear() => _serial(() async {
    final root = await _root();
    await for (final f in root.list(followLinks: false)) {
      if (f is File && (f.path.endsWith('.mp3') || f.path.endsWith('.tmp')))
        await f.delete();
    }
  });
}
