import 'package:sqflite/sqflite.dart';
import '../domain/prayer_diary.dart';
import '../domain/prayer_schedule.dart';

class PrayerDiaryRepository {
  Future<Database>? _opening;
  Future<Database> _db()=>_opening??=_open();
  Future<Database> _open()async{
    final root=await getDatabasesPath();
    return openDatabase('$root/mihrab_diary.db',version:1,onCreate:(db,version)async{
      await db.execute("""
        CREATE TABLE prayer_diary (
          prayer_date TEXT NOT NULL,
          prayer_kind TEXT NOT NULL CHECK(prayer_kind IN ('fajr','dhuhr','asr','maghrib','isha')),
          status TEXT NOT NULL CHECK(status IN ('onTime','qada','missed')),
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          PRIMARY KEY(prayer_date, prayer_kind)
        )
      """);
    });
  }
  Future<DiaryDay> day(DateTime date)async{
    final db=await _db();
    final rows=await db.query('prayer_diary',where:'prayer_date = ?',whereArgs:[diaryDate(date)]);
    return DiaryDay(Map.unmodifiable({for(final row in rows) PrayerKind.values.byName(row['prayer_kind'] as String):PrayerStatus.values.byName(row['status'] as String)}));
  }
  Future<void> mark(DateTime date,PrayerKind kind,PrayerStatus status)async{
    if(!kind.obligatory)throw ArgumentError('Only obligatory prayers');
    final db=await _db();
    final key=diaryDate(date);
    final now=DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn)async{
      final args=[key,kind.name];
      if(status==PrayerStatus.unmarked){
        await txn.delete('prayer_diary',where:'prayer_date = ? AND prayer_kind = ?',whereArgs:args);
      }else{
        final changed=await txn.update('prayer_diary',{'status':status.name,'updated_at':now},where:'prayer_date = ? AND prayer_kind = ?',whereArgs:args);
        if(changed==0)await txn.insert('prayer_diary',{'prayer_date':key,'prayer_kind':kind.name,'status':status.name,'created_at':now,'updated_at':now});
      }
    });
  }
  Future<void> close()async{final opening=_opening;if(opening!=null)await (await opening).close();}
}
