import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adhan_storage.dart';

enum AdhanProfile {
  standard('Обычный азан'), fajr('Азан Фаджра');
  const AdhanProfile(this.label);
  final String label;
}

class AdhanAudio {
  AdhanAudio(this.preferences);
  final SharedPreferences preferences;
  final AudioPlayer player = AudioPlayer();
  static const maxBytes = 15 * 1024 * 1024;
  bool get supported => !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  String? name(AdhanProfile profile) => preferences.getString('adhan_name_${profile.name}');

  Future<bool> import(AdhanProfile profile) async {
    if (!supported) throw UnsupportedError('Импорт доступен на Android и iOS');
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['mp3','wav','m4a'], withData: false);
    if (result == null) return false;
    final file = result.files.single;
    if (file.size <= 0 || file.size > maxBytes || file.path == null) {
      throw const FormatException('Выберите аудиофайл размером до 15 МБ');
    }
    await player.stop();
    final bytes = await readAdhanFile(file.path!, maxBytes);
    if (bytes.isEmpty) throw const FormatException('Пустой аудиофайл');
    await saveAdhanBytes(profile.name, bytes);
    if (!await preferences.setString('adhan_name_${profile.name}', file.name)) {
      throw StateError('Не удалось сохранить название записи');
    }
    return true;
  }

  Future<void> play(AdhanProfile profile) async {
    final bytes = await loadAdhanBytes(profile.name, maxBytes);
    if (bytes == null) throw StateError('Сначала выберите запись');
    await player.stop();
    await player.play(BytesSource(bytes));
  }

  Future<void> stop() => player.stop();

  Future<void> remove(AdhanProfile profile) async {
    await player.stop();
    await deleteAdhanBytes(profile.name);
    await preferences.remove('adhan_name_${profile.name}');
  }

  Future<void> dispose() => player.dispose();
}
