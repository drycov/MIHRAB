import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<File> _file(String profile) async {
  if (profile != 'standard' && profile != 'fajr')
    throw ArgumentError.value(profile);
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  return File('${dir.path}/adhan_$profile.audio');
}

Future<Uint8List> readAdhanFile(String path, int maxBytes) async {
  final file = File(path);
  final builder = BytesBuilder(copy: false);
  await for (final chunk in file.openRead()) {
    if (builder.length + chunk.length > maxBytes)
      throw const FormatException('Файл превышает допустимый размер');
    builder.add(chunk);
  }
  return builder.takeBytes();
}

Future<void> saveAdhanBytes(String profile, Uint8List bytes) async {
  final target = await _file(profile);
  final temporary = File('${target.path}.tmp');
  try {
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(target.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
}

Future<Uint8List?> loadAdhanBytes(String profile, int maxBytes) async {
  final file = await _file(profile);
  return await file.exists() ? readAdhanFile(file.path, maxBytes) : null;
}

Future<void> deleteAdhanBytes(String profile) async {
  final file = await _file(profile);
  if (await file.exists()) await file.delete();
}
