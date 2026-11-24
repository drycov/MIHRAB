import 'dart:typed_data';

Future<Uint8List> readAdhanFile(String path, int maxBytes) async =>
    throw UnsupportedError('Local audio is unavailable');
Future<void> saveAdhanBytes(String profile, Uint8List bytes) async =>
    throw UnsupportedError('Local audio is unavailable');
Future<Uint8List?> loadAdhanBytes(String profile, int maxBytes) async => null;
Future<void> deleteAdhanBytes(String profile) async =>
    throw UnsupportedError('Local audio is unavailable');
