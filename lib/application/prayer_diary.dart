import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/prayer_diary.dart';
import '../infrastructure/prayer_diary_repository.dart';

final diaryRepositoryProvider=Provider<PrayerDiaryRepository>((ref){
  final repo=PrayerDiaryRepository();
  ref.onDispose(()=>unawaited(repo.close()));
  return repo;
});
final diaryDayProvider=FutureProvider.autoDispose.family<DiaryDay,DateTime>((ref,date)=>ref.watch(diaryRepositoryProvider).day(date));
