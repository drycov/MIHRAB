import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;
import '../l10n/reminder_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/widget_snapshot.dart';
import 'schedule.dart';
import 'settings.dart';
import 'hijri_settings.dart';
import 'prayer_diary.dart';

final widgetSyncProvider=Provider<WidgetSync>((ref)=>WidgetSync(ref));
class WidgetSync {
  WidgetSync(this.ref);
  final Ref ref;
  Future<void> _tail=Future.value();
  Future<void> refresh(){
    if(kIsWeb||(defaultTargetPlatform!=TargetPlatform.android&&defaultTargetPlatform!=TargetPlatform.iOS))return Future.value();
    final task=_tail.then((_)async{
      final key=ref.read(localDayProvider);
      final day=DateTime.utc(key.year,key.month,key.day);
      final settings=ref.read(settingsProvider);
      final repository=ref.read(scheduleRepositoryProvider);
      final adjustment=ref.read(hijriAdjustmentProvider);
      int? completed;
      try{completed=(await ref.read(diaryRepositoryProvider).day(day)).completed;}catch(_){}
      final snapshot=WidgetSnapshot.build(settings.city,day,repository,hanafi:key.hanafi,adjustment:adjustment,now:DateTime.now(),completed:completed,language:resolveReminderLanguage(ref.read(preferencesProvider).getString('app_locale_v1'),PlatformDispatcher.instance.locales));
      await const MethodChannel('mihrab/widgets').invokeMethod<void>('publish',jsonEncode(snapshot));
    });
    _tail=task.then<void>((_){},onError:(Object e,StackTrace s){debugPrint('Widget update failed: $e');});
    return _tail;
  }
}
