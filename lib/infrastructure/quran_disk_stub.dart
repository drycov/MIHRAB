import 'dart:typed_data';
class QuranDisk {
  static const supported=false;
  static const limit=256*1024*1024;
  static Future<Uint8List?> read(String key)async=>null;
  static Future<void> write(String key,Uint8List bytes)async=>throw UnsupportedError('Disk unavailable');
  static Future<bool> contains(String key)async=>false;
  static Future<int> size()async=>0;
  static Future<void> clear()async{}
}
