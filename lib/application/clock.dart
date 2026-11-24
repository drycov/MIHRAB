import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clockProvider = NotifierProvider.autoDispose<Clock, DateTime>(Clock.new);
class Clock extends AutoDisposeNotifier<DateTime> {
  @override
  DateTime build() {
    final timer = Timer.periodic(const Duration(seconds: 1), (_) => state = DateTime.now());
    ref.onDispose(timer.cancel);
    return DateTime.now();
  }
}
