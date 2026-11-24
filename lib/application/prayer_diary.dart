import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/prayer_diary.dart';
import '../domain/prayer_statistics.dart';
import '../infrastructure/prayer_diary_repository.dart';

final diaryRepositoryProvider = Provider<PrayerDiaryRepository>((ref) {
  final repo = PrayerDiaryRepository();
  ref.onDispose(() => unawaited(repo.close()));
  return repo;
});
final diaryDayProvider = FutureProvider.autoDispose.family<DiaryDay, DateTime>(
  (ref, date) => ref.watch(diaryRepositoryProvider).day(date),
);

typedef StatisticsPeriod = ({DateTime end, int length});
final prayerStatisticsProvider = FutureProvider.autoDispose.family<
  PrayerStatistics,
  StatisticsPeriod
>((ref, period) async {
  if (period.length < 1 || period.length > 366)
    throw RangeError.range(period.length, 1, 366);
  final end = DateTime.utc(period.end.year, period.end.month, period.end.day);
  final start = end.subtract(Duration(days: period.length - 1));
  final records = await ref.watch(diaryRepositoryProvider).range(start, end);
  return PrayerStatistics(end, period.length, records);
});
