import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite serializes writers across Flutter engines. Do not use this database
/// for other application operations while the scheduling transaction is open.
class ReminderLock {
  static Future<Database>? _database;
  static Future<Database> _open() async {
    final directory = await getDatabasesPath();
    return openDatabase('$directory/mihrab_scheduler.db', version: 1,
      onCreate: (db, version) => db.execute(
        'CREATE TABLE scheduler_lock (id INTEGER PRIMARY KEY, revision INTEGER NOT NULL)'));
  }

  static Future<T> run<T>(Future<T> Function() action) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return action();
    final db = await (_database ??= _open());
    return db.transaction((txn) async {
      await txn.rawInsert('INSERT OR IGNORE INTO scheduler_lock VALUES (1, 0)');
      await txn.rawUpdate('UPDATE scheduler_lock SET revision = revision + 1 WHERE id = 1');
      return action();
    }, exclusive: true);
  }
}
