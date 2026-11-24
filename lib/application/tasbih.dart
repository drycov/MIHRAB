import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/tasbih.dart';
import 'settings.dart';

final tasbihProvider = NotifierProvider<TasbihController, TasbihState>(
  TasbihController.new,
);

class TasbihController extends Notifier<TasbihState> {
  static const key = 'tasbih_state_v1';
  Future<void> _tail = Future.value();
  @override
  TasbihState build() {
    final raw = ref.watch(preferencesProvider).getString(key);
    if (raw == null) return const TasbihState();
    return TasbihState.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  Future<void> _change(TasbihState Function(TasbihState) change) {
    final task = _tail.then((_) async {
      final next = change(state);
      if (identical(next, state)) return;
      if (!await ref
          .read(preferencesProvider)
          .setString(key, jsonEncode(next.toJson())))
        throw StateError('Не удалось сохранить тасбих');
      state = next;
    });
    _tail = task.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return task;
  }

  Future<void> increment() => _change((s) => s.increment(DateTime.now()));
  Future<void> reset() => _change((s) => s.reset());
  Future<void> configure(Dhikr d, int target) =>
      _change((s) => s.configure(d, target));
  Future<void> vibration(bool value) => _change((s) => s.vibration(value));
  Future<void> clearHistory() => _change((s) => s.clearHistory());
}
