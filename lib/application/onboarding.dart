import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings.dart';

final onboardingProvider = NotifierProvider<OnboardingController, bool>(OnboardingController.new);
class OnboardingController extends Notifier<bool> {
  static const key = 'onboarding_completed_v1';
  @override
  bool build() {
    final prefs = ref.watch(preferencesProvider);
    return prefs.getBool(key) ?? (prefs.containsKey('city') || prefs.containsKey('reminder_config_v1') || prefs.containsKey('reminder_prayers'));
  }
  Future<void> complete() async {
    if (!await ref.read(preferencesProvider).setBool(key,true)) {
      throw StateError('Не удалось сохранить состояние первоначальной настройки');
    }
    state = true;
  }
}
