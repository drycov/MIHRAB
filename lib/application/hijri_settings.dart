import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings.dart';

final hijriAdjustmentProvider = NotifierProvider<HijriAdjustment, int>(HijriAdjustment.new);
class HijriAdjustment extends Notifier<int> {
  @override
  int build() => (ref.watch(preferencesProvider).getInt('hijri_adjustment') ?? 0).clamp(-2,2).toInt();
  Future<void> change(int value) async {
    if (value < -2 || value > 2) return;
    if (!await ref.read(preferencesProvider).setInt('hijri_adjustment',value)) {
      throw StateError('Не удалось сохранить корректировку');
    }
    state = value;
  }
}
